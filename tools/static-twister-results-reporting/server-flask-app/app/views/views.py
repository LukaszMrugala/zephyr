#!/usr/bin/python

import os, glob, tarfile
from datetime import datetime
from flask import Blueprint, render_template, request, abort, send_file
from jinja2 import TemplateNotFound
from app.models.platform import Daily_Platforms_Report, Platform_Report
from app.models.component import ComponentStatus
from app.config import *
from app.config_local import *

main_blueprint = Blueprint('main', __name__, template_folder='templates')

@main_blueprint.route('/', methods=['GET'])
@main_blueprint.route('/index', methods=['GET'])
@main_blueprint.route('/index.html', methods=['GET'])
def index():
    try:
        run_date = request.args.get('run-date') # get run_date from url
        branch = request.args.get('branch')     # get branch name from url
        n = APP_SHOW_NDAYS

        results = Daily_Platforms_Report(branch, run_date)

        data = render_template('index.html'
                , date_runs = results.date_runs[:n]
                , branch_list = results.branch_dict
                , platforms = results.platforms
                , run_date_time = results.environment['run_date']
                , branch = results.branch_name
                , commit_date = results.environment['commit_date']
                , zephyr_version = results.environment['zephyr_version']
                , table = results.data_for_www.to_html(index=False, table_id='dataTablePlatforms', classes='table table-bordered')
                , table_failures_s = results.failures_df.to_html(index=False, table_id='dTFailuresSuites'
                                                                    , classes='table table-bordered display nowrap w-100')
                )

        del results

        return data

    except TemplateNotFound as err:
        abort(404)
    except SystemError as err:
        abort(500)
    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        raise


@main_blueprint.route('/platform', methods=['GET'])
@main_blueprint.route('/platform/index.html', methods=['GET'])
def platform():
    try:
        run_date = request.args.get('run-date') # get run_date from url
        branch = request.args.get('branch')     # get branch name from url
        platform = request.args.get('p')        # get platform name from url
        n = APP_SHOW_NDAYS                      # get first n runs

        results = Platform_Report(branch, run_date, platform)

        results.get_data()

        data = render_template('platform.html'
                , tests_result = results.tests_result
                , date_runs = results.date_runs[:n]
                , branch_list = results.branch_dict
                , platforms = results.platforms
                , run_date = results.run_date
                , branch = results.branch_name
                , platform = results.platform
                , platform_path = results.platforms[results.platform]
                , run_date_time = results.environment['run_date']
                , commit_date = results.environment['commit_date']
                , zephyr_version = results.environment['zephyr_version']
                , arch = results.environment['arch']
                , table = results.test_failed.to_html(index=False, table_id='dataTableFailures', classes='table table-bordered')
                )

        del results

        return data

    except TemplateNotFound:
        abort(404)
    except SystemError as err:
        abort(500)
    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        raise


@main_blueprint.route('/components', methods=['GET'])
@main_blueprint.route('/components/index.html', methods=['GET'])
def components():
    try:
        run_date = request.args.get('run-date') # get run_date from url
        branch = request.args.get('branch')     # get branch name from url
        n = APP_SHOW_NDAYS

        results = ComponentStatus(branch, run_date)

        data = render_template('components.html'
                , date_runs = results.date_runs[:n]
                , branch_list = results.branch_dict
                , platforms = results.platforms_dict
                , branch = results.branch_name
                , table_comp_s = results.ts_component_summary.to_html(index=False, table_id='dTComponentSuites'
                                                                    , classes='table table-bordered display nowrap w-100 dt-components')
                , table_failures_s = results.ts_failures.to_html(index=False, table_id='dTFailuresSuites'
                                                                    , classes='table table-bordered display nowrap w-100')
                , table_comp_c = results.tc_component_summary.to_html(index=False, table_id='dTComponentCases'
                                                                    , classes='table table-bordered display nowrap w-100 dt-components')
                , table_failures_c = results.tc_failures.to_html(index=False, table_id='dTFailuresCases'
                                                                    , classes='table table-bordered display nowrap w-100')
                , run_date_time = results.environment['run_date']
                , commit_date = results.environment['commit_date']
                , zephyr_version = results.environment['zephyr_version']
               )

        del results

        return data

    except TemplateNotFound:
        abort(404)
    except SystemError as err:
        abort(500)
    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        raise


# download function for download files
# <a href="{{ url_for('download', filename="downloadFile.txt") }}">File</a>
@main_blueprint.route('/download/<path:filename>', methods=['GET', 'POST'])
def download_logs(filename):
    run_date = datetime.strptime(request.args.get('run_date'), DATE_FORMAT_LONG).strftime(DATE_FORMAT_SHORT)
    branch = BRANCH_DICT[request.args.get('branch')]
    subset_name = request.args.get('subset_name')
    platform = request.args.get('platform')

    if filename in ['twister.log', 'twister.json']:
        # twister.log || twister.json
        path = os.path.join(DATA_PATH, branch, run_date, subset_name, filename)
    else:
        # build.log || device.log || handler.log
        test = request.args.get('test_suite')
        path = os.path.join(DATA_PATH, branch, run_date)

        # search for filename.log file
        file = glob.glob(f"{path}/*{platform}-twister-out*/**/{test}/{filename}", recursive=True)

        if not file:
            # filename.log does not exist, then search twister-out archives
            # search for twister-out tar.gz archive
            file = glob.glob(f"{path}/*{platform}-twister-out*/*.tar.gz", recursive=True)

            if file:
                # unzip twister-out archive
                with tarfile.open(file[0], 'r') as tar:
                    file = glob.glob(f"{path}/*{platform}-twister-out*/", recursive=True)
                    tar.extractall(file[0])
            
            # search for filename.log file
            file = glob.glob(f"{path}/*{platform}-twister-out*/**/{test}/{filename}", recursive=True)
        
        if file:
            # handler.log exists
            path = file[0]
        else:
            # handler.log does not exist
            abort(404)
    
    # Returning file from appended path
    return send_file(path_or_file=path, as_attachment=True, download_name=f'{platform}-{filename}')


# subset-11-intel_ish_5_4_1-twister-out archive in .tar.gz format/twister-out/intel_ish_5_4_1/tests/benchmarks/app_kernel/benchmark.kernel.application.timeslicing/handler.log