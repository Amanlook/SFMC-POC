import random

def hello_world():
    return 'Hello, World!'

def status():
    return {'status': True}, 200

def random_status():
    status_codes = {
        200: 'OK',
        201: 'Created',
        400: 'Bad Request',
        401: 'Unauthorized',
        403: 'Forbidden',
        404: 'Not Found',
        500: 'Internal Server Error'
    }
    code = random.choice(list(status_codes.keys()))
    return {
        'status': status_codes[code],
        'status_code': code
    }, code
