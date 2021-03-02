from time import time
from hashlib import sha256
from random import random
from cloudant.client import CouchDB
from flask import g, request

DB_SOL_NAME = 'classpack'
DB_USR_NAME = 'users'
DB_PRB_NAME = 'problems'

__DB_USERNAME = None
__DB_PASSWORD = None
__DB_ADDRESS  = None


def init_db(config, app):

    global __DB_ADDRESS, __DB_PASSWORD, __DB_USERNAME

    app.teardown_appcontext(disconnect)

    __DB_USERNAME = config.get('ClassPack', 'db.username', fallback='classpack_user')
    __DB_PASSWORD = config.get('Database', 'db.password')
    __DB_ADDRESS  = config.get('Database', 'db.address', fallback='http://127.0.0.2')
    

def save_problem(json_data):

    if '_client' not in g: return

    db = g._client[DB_PRB_NAME]

    id = sha256(str(time() + random()).encode('latin')).hexdigest()

    doc = {
        '_id': id,
        'user_ip': request.remote_addr,
        'user_agent': str(request.user_agent),
        'timestamp': time()
        }

    doc.update(json_data)

    db.create_document(doc)


def connect():
    """
    Conect to the CouchDB server.
    """

    if __DB_ADDRESS  is None or \
       __DB_PASSWORD is None or \
       __DB_USERNAME is None:

        print("Database not initialized.")

        return None
    
    try:
        
        g._client = CouchDB(__DB_USERNAME, __DB_PASSWORD,
                            url=__DB_ADDRESS + ':5984', connect=True)

    except Exception as e:

        print("Error when connecting to database")

        pass


def disconnect(e=None):
    """
    Disconnect from the CouchDB server.
    """

    if '_client' not in g: return
    
    g._client.disconnect()


def _sort_obs(obstacles):
    """

    Sort the list of triples (given by lists) `obstacles`. The idea is to
    first sort by `x`, then by `y` and then by the `radius` of the
    obstacle.

    """

    for i in range(0, len(obstacles) - 1):

        pmin = i
        vmin = obstacles[i]

        for j in range(i + 1, len(obstacles)):

            jobs = obstacles[j]

            if vmin[0] > jobs[0] or \
               (vmin[0] == jobs[0] and vmin[1] > jobs[1]) or \
               (vmin[0] == jobs[0] and vmin[1] == jobs[1] and vmin[2] > jobs[2]):

                pmin = j
                vmin = obstacles[j]

        if pmin is not i:

            tmp = obstacles[i]
            obstacles[i] = vmin
            obstacles[pmin] = tmp

def add_and_return_user(email, name, institution):
    """Store the user and return the document.

    NOTE: the user is always stored, even if the email already
    exists. This solves the problem of wrong email addresses and
    different information. Also, avoids the need for passwords.

    """

    if '_client' not in g: return ''
    
    udb = g._client[DB_USR_NAME]

    uid = sha256((email + str(time())).encode('latin')).hexdigest()

    user_with_id = {
        '_id': uid,
        'email': email,
        'name': name,
        'institution': institution
    }

    udb.create_document(user_with_id)
    
    return uid


def gen_chair_id(width, height, min_dist, ch_width, ch_height,
                 obstacles, ptype, num_chairs):
    """Generate unique ids for saving the results of 'chairs' problems.

    """

    _sort_obs(obstacles)

    num_chairs_str = ""
    if num_chairs is not None: num_chairs_str = str(num_chairs)
    
    id = 'chairs:' + ':'.join(
        str(i) for i in [width, height, ch_width, ch_height, min_dist] +
        list(k for ob in obstacles for k in ob) +
        [ptype, num_chairs_str]
    )

    return id


def gen_row_id(width, height, min_dist, ch_width, ch_height,
               n_rows, n_chairs):
    """Generate unique ids for saving the results of 'rows' problems.

    """

    id = 'rows:' + ':'.join(
        str(i) for i in [width, height, ch_width, ch_height, min_dist, n_rows, n_chairs]
    )

    return id


def get_chairs(problem_id):

    if '_client' not in g: return None

    db = g._client[DB_SOL_NAME]

    if problem_id in db:

        doc = db[problem_id]

        return doc['solution']

    return None


def get_rows(problem_id):

    if '_client' not in g: return None

    db = g._client[DB_SOL_NAME]

    if problem_id in db:

        doc = db[problem_id]

        return doc['solution']

    return None


def save_or_update_chairs(problem_id, width, height, min_dist, ch_width, ch_height,
                          ptype, solution, obstacles=[], num_chairs=None):

    if '_client' not in g: return
    
    db = g._client[DB_SOL_NAME]

    if problem_id in db:

        olddoc = db[problem_id]

        if solution['min_distance'] < olddoc['solution']['min_distance']:

            olddoc['solution'] = solution
            olddoc.save()

            print('Updated cache')

    else:

        document = {
            '_id': problem_id,
            'problem_type': ptype,
            'num_chairs': num_chairs,
            'min_dist': min_dist,
            'room_width': width,
            'room_height': height,
            'chair_width': ch_width,
            'chair_height': ch_height,
            'obstacles': obstacles,
            'solution': solution
        }

        doc = db.create_document(document)

        print("Added to cache")


def save_or_update_rows(problem_id, width, height, min_dist, ch_width, ch_height,
                        n_rows, n_chairs, solution):

    if '_client' not in g: return
    
    db = g._client[DB_SOL_NAME]

    if problem_id in db:

        olddoc = db[problem_id]

        if int(olddoc['solution']['status']) is '0' or \
           solution['students'] > olddoc['solution']['students']:

            olddoc['solution'] = solution
            olddoc.save()

            print('Updated cache')

    else:

        document = {
            '_id': problem_id,
            'min_dist': min_dist,
            'room_width': width,
            'room_height': height,
            'chair_width': ch_width,
            'chair_height': ch_height,
            'number_of_chairs': n_chairs,
            'number_of_rows': n_rows,
            'solution': solution
        }

        doc = db.create_document(document)

        print("Added to cache")
