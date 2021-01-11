from configparser import ConfigParser
from flask import Flask
from flask_cors import CORS


# Factory
def create_app(ini_file):

	app = Flask(__name__)
	CORS(app)

	config = ConfigParser()
	config.read(ini_file)

	__URL_PREFIX = config.get('ClassPack', 'url.prefix', fallback='/')

	from optimizer import optimizer, config_optimizer
	config_optimizer(config)
	app.register_blueprint(optimizer, url_prefix=__URL_PREFIX)

	from database import init_db
	init_db(config, app)

	return app


if __name__ == '__main__':

	app = create_app("./cp_config.ini")

	app.run(host="0.0.0.0")
