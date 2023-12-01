#!/usr/bin/python

from flask import Blueprint, render_template, request
from app.models.platform import Daily_Platforms_Report, Platform_Report
from app.models.component import ComponentStatus
from app.config import *

main_blueprint = Blueprint('main', __name__, template_folder='templates')

@main_blueprint.route('/')
@main_blueprint.route('/index', methods=['GET'])
def index():
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
            )

    del results
    
    return data

@main_blueprint.route('/platform', methods=['GET'])
def platform():
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
            , run_date_time = results.environment['run_date']
            , run_date = results.run_date
            , branch = results.branch_name
            , commit_date = results.environment['commit_date']
            , zephyr_version = results.environment['zephyr_version']
            , platform = results.platform
            , arch = results.environment['arch']
            , table = results.test_failed.to_html(index=False, table_id='dataTableFailures', classes='table table-bordered')
            )
    
    del results

    return data

@main_blueprint.route('/components', methods=['GET'])
def components():
    run_date = request.args.get('run-date') # get run_date from url
    branch = request.args.get('branch')     # get branch name from url
    n = APP_SHOW_NDAYS

    results = ComponentStatus(branch, run_date)
    
    data = render_template('components.html'
            , date_runs = results.date_runs[:n]
            , branch_list = results.branch_dict
            , platforms = results.platforms
            , branch = results.branch_name
            , table_comp_s = results.ts_component_summary.to_html(index=False, table_id='dTComponentSuites'
                                                                  , classes='table table-bordered display nowrap w-100 dt-components')
            , table_failures_s = results.ts_failures.to_html(index=False, table_id='dTFailuresSuites'
                                                                  , classes='table table-bordered display nowrap w-100')
            , table_comp_c = results.tc_component_summary.to_html(index=False, table_id='dTComponentCases'
                                                                  , classes='table table-bordered display nowrap w-100 dt-components')
            , run_date_time = results.environment['run_date']
            , commit_date = results.environment['commit_date']
            , zephyr_version = results.environment['zephyr_version']
            )

    del results
    
    return data

def error500():
    return render_template('500.html')
