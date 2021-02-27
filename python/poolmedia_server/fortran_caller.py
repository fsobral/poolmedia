from flask import Blueprint, current_app


__FORTRAN_EXEC_NAME = 'program.x'
__FORTRAN_EXEC_PATH = './'


def config_fortran_caller(config):

    global __FORTRAN_EXEC_NAME, __FORTRAN_EXEC_PATH

    __FORTRAN_EXEC_NAME = config.get('Poolmedia', 'fortran.exec.name', fallback='program.x')
    __FORTRAN_EXEC_PATH = config.get('Poolmedia', 'fortran.exec.path', fallback='./')


optimizer = Blueprint('mainapp', __name__)

@optimizer.route('/')
def index():

    from flask import render_template
    return render_template('form.html')

@optimizer.route('/poolmedia', methods=['GET'])
def call_fortran():
    import subprocess

    global __FORTRAN_EXEC_NAME, __FORTRAN_EXEC_PATH

    from flask import request
    d = request.args

    minindinf = d.get('minindinf', type=float)
    maxindinf = d.get('maxindinf', type=float)
    numbstrat = d.get('numbstrat', type=int)
    maxm1size = d.get('maxm1size', type=int)
    maxnstage = d.get('maxnstage', type=int)
    wantsimul = d.get('wantsimul', type=int)
    populsize = d.get('populsize', type=int)
    parapools = d.get('parapools', type=int)

    # Check is some parameter is missing and return error if true
    if minindinf is None or \
       maxindinf is None or \
       numbstrat is None or \
       maxm1size is None or \
       maxnstage is None or \
       wantsimul is None or \
       ( wantsimul is 1 and (
           populsize is None or \
           parapools is None )
       ):

        current_app.logger.info('Bad request. Arguments\n\t minindinf {0:s}\n\t maxindinf {1:s}\n\t numbstrat {2:s}\n\t maxm1size {3:s}\n\t maxnstage {4:s}\n\t wantsimul {5:s}\n\t populsize {6:s}\n\t parapools {7:s}'.format(
            *(str(i) for i in [minindinf, maxindinf, numbstrat,
                               maxm1size, maxnstage, wantsimul,
                               populsize, parapools])
        ))
        
        return "Bad request.", 400

    # Construct a random output file name
    from time import time
    from hashlib import sha256
    from random import random
    rand_file_name = sha256(str(time() + random()).encode('latin')).hexdigest() + '.tmp'

    args = [rand_file_name, minindinf, maxindinf, numbstrat, maxm1size, maxnstage, 0,
            wantsimul]

    if wantsimul is 1:
        args += [populsize, parapools]
        
    current_app.logger.debug(str(args))

    try:

        process = subprocess.Popen(
            [__FORTRAN_EXEC_PATH + '/' + __FORTRAN_EXEC_NAME],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )

        # Convert to string and call Fortran
        output, error = process.communicate(
            '\n'.join(
                (str(i) for i in args)
            ).encode('utf-8'))

        current_app.logger.debug('Fortran output:\n{0:s}'.format(output))

    except Exception as e:

        current_app.logger.error('Error when running Fortran executable. Arguments {0:s}. Error {1:s}'.format(str(args), str(e)))

        return '{0}()'.format(
            request.args.get('callback')), 500

    else:

        from os import remove
        from json import loads, dumps

        # Finish Fortran process
        process.terminate()

        try:
        
            loaded_json = loads(open(rand_file_name, 'r').read())

            current_app.logger.debug(loaded_json)

        except OSError as e:

            current_app.logger.error('Unable to open file {0:s}. Error {1:s}'.format(rand_file_name, str(e)))

        except Exception as e:

            current_app.logger.error('Unable to parse JSON from file {0:s}. Error {1:s}'.format(rand_file_name, str(e)))

            # Remove json file and finish process
            remove(rand_file_name)

        finally:

            return 'Server error.', 500

        # Remove json file
        remove(rand_file_name)

        current_app.logger.info('Successfully solved problem {0:s}'.format(str(args)))

        return '{0}({1})'.format(
            request.args.get('callback'),
            dumps(loaded_json)
        )
