from flask import Blueprint


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
        
    print(args)

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

    except Exception as e:

        print(e)

        return '{0}()'.format(
            request.args.get('callback')), 500

    else:

        from os import remove
        from json import loads, dumps
        
        loaded_json = loads(open(rand_file_name, 'r').read())
        print(loaded_json)

        # Remove json file and finish process
        remove(rand_file_name)
        process.terminate()

        return '{0}({1})'.format(
            request.args.get('callback'),
            dumps(loaded_json)
        )
