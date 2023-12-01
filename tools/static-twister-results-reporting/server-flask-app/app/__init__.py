# app/__init__.py

from flask import Flask
from flask_fontawesome import FontAwesome
from flask_bootstrap import Bootstrap

from .containers import Container

# Initialize Flask Application
def create_app():
  container = Container()

  app = Flask(__name__)
  app.config['TESTING'] = True

  # Load common settings
  app.config.from_object('app.config')

  # Load environment specific settings
  app.config.from_object('app.config_local')

  # Now we can access the configuration variables via app.config["VAR_NAME"].

  app.container = container

  fa = FontAwesome(app)

  bootstrap = Bootstrap()
  bootstrap.init_app(app)

  # Register blueprints
  from .views import register_blueprints
  register_blueprints(app)

  return app
