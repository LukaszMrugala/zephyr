# FMOS static twister results reporting server - scripts

FMOS static twister results reporting server that web page for presenting results of twister run.
All data are pulling from twister.json file stored in twister-out directory after twister ends tests.

Wiki page [link](https://wiki.ith.intel.com/display/timo/%5BDaily+Test%5D%3A+Static+Report+Setup+and+Daily+Test+Dashboard)

## Function Summary 

**[platforms](//zep-fmos-static-reporting.igk.intel.com)** - show twister test results for all platforms loaded from twister.json file
![Platforms.](/tools/static-twister-results-reporting/assets/images/print-screen-platforms.jpg)

**[platform](//zep-fmos-static-reporting.igk.intel.com/platform?p=frdm_k64f)** - show twister test results for the selected platform
![Platform.](/tools/static-twister-results-reporting/assets/images/print-screen-platform.jpg)

**[components](//zep-fmos-static-reporting.igk.intel.com/components)** - show twister test result for components and subcomponents loaded from twister.json file
![Components.](/tools/static-twister-results-reporting/assets/images/print-screen-components.jpg)

## Deployment

### Prepare the environment:

1. For server.

Create a project folder:
```
mkdir static-reporting
cd static-reporting
```

Clone files from github repository:
  `https://github.com/intel-innersource/os.rtos.zephyr.devops.ci/tree/main/tools/static-twister-results-reporting/server-flask-app`

Now let's verify app setting and set path to twister out data:
Section # Paths settings in app/config_local.py file
```
DATA_PATH = r'/path/to/branches/directory/'
```
> [!NOTE]
> Data layout for deployment on a server:
> ```
> DATA_PATH/
> |-- branch_name/
> |   |-- run_date/
> |   |   |-- twister_out/
> |   |   |   |-- twister.json
> |   |-- run_date2/
> |   |   |-- twister_out/
> |   |   |   |-- twister.json
> |-- branch_name_2/
> |   |-- run_date/
> |   |   |-- twister_out/
> |   |   |   |-- twister.json
> ```

Now let’s create and activate virtual environment:
```
python3 -m venv venv
. venv/bin/activate
```

Install requirements:
```
pip install -r requirements.txt
```

Run run flask app:
```
flask run
```

The output should be something like:
```
* Serving Flask app 'static_reports.py' (lazy loading)
* Environment: production
  WARNING: This is a development server. Do not use it in a production deployment.
  Use a production WSGI server instead.
* Debug mode: off
* Running on all addresses.
  WARNING: This is a development server. Do not use it in a production deployment.
* Running on http://192.168.0.2:8080/ (Press CTRL+C to quit)
```

**Contacts: Artur Wilczak
