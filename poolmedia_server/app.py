from configparser import ConfigParser
from flask import Flask
from flask_cors import CORS

import logging
from logging.handlers import RotatingFileHandler

# Factory
def create_app(ini_file):

    # Load configuration file
    
    config = ConfigParser()
    config.read(ini_file)

    # Set root logger for Flask

    __LOG_FILENAME = config.get('Poolmedia', 'logging.filename', fallback='poolmedia.log')
    __LOG_LEVEL = config.get('Poolmedia', 'logging.level', fallback='INFO')
    
    root = logging.getLogger()
    handler = RotatingFileHandler(__LOG_FILENAME, maxBytes=1024*1024, backupCount=5)
    handler.setFormatter(logging.Formatter('[%(asctime)s] %(levelname)s in %(module)s: %(message)s'))
    root.addHandler(handler)
    root.setLevel(__LOG_LEVEL)
    
    app = Flask(__name__)
    CORS(app)

    __URL_PREFIX = config.get('Poolmedia', 'url.prefix', fallback='/')

    from poolmedia_server.fortran_caller import optimizer, config_fortran_caller
    config_fortran_caller(config)
    app.register_blueprint(optimizer, url_prefix=__URL_PREFIX)

    # from database import init_db
    # init_db(config, app)

    app.logger.info('App successfully created.')

    return app


if __name__ == '__main__':

    app = create_app("./pm_config.ini")

    app.run(host="0.0.0.0")
