# app/__init__.py

from flask import Flask, render_template
from flask_fontawesome import FontAwesome
from flask_bootstrap import Bootstrap

from .containers import Container

def page_not_found(e):
  return render_template('404.html'), 404

def internal_server_error(e):
    return render_template('500.html'), 500

# Initialize Flask Application
def create_app():
  try:
    container = Container()

    app = Flask(__name__)
    app.config['TESTING'] = True

    # Load common settings
    app.config.from_object('app.config')

    # Load environment specific settings
    app.config.from_object('app.config_local')

    # Now we can access the configuration variables via app.config["VAR_NAME"].

    app.register_error_handler(404, page_not_found)
    app.register_error_handler(500, internal_server_error)

    app.container = container

    fa = FontAwesome(app)

    bootstrap = Bootstrap()
    bootstrap.init_app(app)

    # Register blueprints
    from .views import register_blueprints
    register_blueprints(app)

    return app

  except Exception as err:
    print(f"Unexpected {err=}, {type(err)=}")
    raise
