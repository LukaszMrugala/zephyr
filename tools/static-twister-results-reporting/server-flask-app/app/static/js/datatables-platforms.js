// Call the dataTables jQuery plugin
$(document).ready(function() {
  let server_mode = Boolean(parseInt(sessionStorage.getItem('server_mode')));

  // Test Suites TAB

  $('#dt-platforms-ts').DataTable( {
    paging: false
    // , pageLength: 50
    // , scrollX: true
    // , scrollY: false
    // , colReorder: true
    // , autoWidth: false
    // , fixedHeader: true
    // , deferRender: false
    , dom: 'Bfrltip'
    , buttons: [
      {
        extend: 'copy'
        , title: 'Results of test suites by platforms'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'print'
        , title: 'Results of test suites by platforms'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'csv'
        , title: 'Results of test suites by platforms'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> CSV'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'excelHtml5'
        , title: 'Results of test suites by platforms'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> Excel'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
    ]
    , order: [
      [1, 'asc']
    ]
    , columns: [
      {
        data: 'status'
        , visible: false
      }
      , {
        data: 'platform'
        , className: 'printable'
        , render: function(data, type, row) {
            queryString = window.location.search;
            const params = new URLSearchParams(queryString);
            params.set('p', data);
            return `<a href="/platform?${params.toString()}" title="${data}">${data}</a>`;
        }
        , title: 'platform name'
      }
      , {
        data: 'pass_rate'
        , title: 'pass rate <i class="fa fa-info-circle" data-toggle="tooltip" title="Test suite pass rate excluding skipped cases"></i>'
        , class: 'pass-rate-progresbar printable'
        , width: '20%'
        , searchable: false
        , render: function(data) {
            var color = 'bg-passrate-100'
            if (data < 100) { color = ' bg-passrate-99' }
            if (data < 99) { color = ' bg-passrate-98' }
            if (data < 95) { color = ' bg-passrate-95' }
            if (data < 90) { color = ' bg-passrate-90' }
            return `<div class="progress">
              <div class="progress-bar ${color}" role="progressbar"
                  style="width: ${data}%;" aria-valuenow="${data}" aria-valuemin="0"
                  aria-valuemax="100"><span>${parseFloat(data).toFixed(2)} %</span></div>
              </div>`;
        }
      }
      , {
        data: 'test_suites'
        , title: 'test suites <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of test suites marked as runnable for this platform"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'passed'
        , title: 'passed <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of passed test suites"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'failed'
        , title: 'failed <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of failed test suites"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'error'
        , title: 'error <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of test suites that ended with an error"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'blocked'
        , title: 'blocked <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of test suites that return status blocked"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'skipped'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
    ]
    , initComplete: function() {
      $('#dt-platforms-ts_filter input').attr('id', 'dt-platforms-ts-search');
      // dtPlatformsTc.api().ajax.reload();
    }
  } );

  // Summary table for Test Cases
  $('#dt-platforms-tc').DataTable( {
    pageLength: 50
    , paging: false
    , colReorder: true
    , autoWidth: false
    , fixedHeader: true
    , deferRender: false
    , dom: 'Bfrltip'
    , buttons: [
      {
        extend: 'copy'
        , title: 'Results of test cases by platforms'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'print'
        , title: 'Results of test cases by platforms'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'csv'
        , title: 'Results of test cases by platforms'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> CSV'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'excelHtml5'
        , title: 'Results of test cases by platforms'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> Excel'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
    ]
    , order: [
      [1, 'asc']
    ]
    , columns: [
      {
        data: 'testcases_status'
        , visible: false
      }
      , {
        data: 'platform'
        , className: 'printable'
        , render: function(data, type, row) {
            queryString = window.location.search;
            const params = new URLSearchParams(queryString);
            params.set('p', data);
            return `<a href="/platform?${params.toString()}" title="${data}">${data}</a>`;
        }
        , title: 'platform name'
      }
      , {
        data: 'pass_rate'
        , title: 'pass rate <i class="fa fa-info-circle" data-toggle="tooltip" title="Test case pass rate excluding skipped cases"></i>'
        , class: 'pass-rate-progresbar printable'
        , width: '20%'
        , searchable: false
        , render: function(data) {
            var color = 'bg-passrate-100'
            if (data < 100) { color = ' bg-passrate-99' }
            if (data < 99) { color = ' bg-passrate-98' }
            if (data < 95) { color = ' bg-passrate-95' }
            if (data < 90) { color = ' bg-passrate-90' }
            return `<div class="progress">
              <div class="progress-bar ${color}" role="progressbar"
                  style="width: ${data}%;" aria-valuenow="${data}" aria-valuemin="0"
                  aria-valuemax="100"><span>${parseFloat(data).toFixed(2)}%</span></div>
              </div>`;
        }
      }
      , {
        data: 'test_cases'
        , title: 'test cases <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of test cases marked as runnable for this platform"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
        , render: function(data) {
            return `<span data-toggle="tooltip" title="Count of test cases marked as runnable for this platform">${data}</span>`;
        }
      }
      , {
        data: 'passed'
        , title: 'passed <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of passed test cases"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'failed'
        , title: 'failed <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of failed test cases"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'error'
        , title: 'error <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of test cases that ended with an error"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'blocked'
        , title: 'blocked <i class="fa fa-info-circle" data-toggle="tooltip" title="Count of test cases that return status blocked"></i>'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'skipped'
        , className: 'text-right printable'
        , width: '7%'
        , searchable: false
      }
    ]
    , initComplete: function() {
      $('#dt-platforms-tc_filter input').attr('id', 'dt-platforms-tc-search');
    }
  } );

  // Datatables Test Suites Failures  - Begin
  DataTable.ext.errMode = 'none';
  var collapsedTSFailuresGroups = {};
  var oSuitesFailuresTable = $('#test-suites-fails').DataTable( {
    paging: false
    // , colReorder: true
    , autoWidth: false
    // , fixedHeader: true
    , deferRender: false
    , dom: 'Bfrtip'
    , buttons: [
      {
        extend: 'copy'
        , title: 'Test suites that failed or error'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'print'
        , title: 'Test suites that failed or error'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'csv'
        , title: 'Test suites that failed or error'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> CSV'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'excelHtml5'
        , title: 'Test suites that failed or error'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> Excel'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
    ]
    , order: [[0, 'asc']]
    , columns: [
      {
        data: 'platform'
        , className: 'printable'
      }
      , {
        data: 'name'
        , title: 'test suite name'
        , className: 'printable'
      }
      , {
        data: 'reason'
        , className: 'printable'
      }
      , {
        data: 'status'
        , className: 'printable'
      }
    ]
    , rowGroup: {
      dataSrc: 'platform'
      , startRender: function(rows, group) {
        var collapsed = !!collapsedTSFailuresGroups[group];

        rows.nodes().each(function(r) {
          r.style.display = collapsed ? '' : 'none';
        });

        // Add category name to the <tr>. NOTE: Hardcoded colspan
        return $('<tr/>')
          .append('<td colspan="4">' + group + ' (' + rows.count() + ')</td>')
          .attr('data-name', group)
          .toggleClass('collapsed', collapsed)
          .attr('id', 'ts-' + group);
      }
    }
    , initComplete: function() {
      $('#test-suites-fails_filter input').attr('id', 'test-suites-fails-search');
    }
  } );

  $('#test-suites-fails tbody').on('click', 'tr.dtrg-start', function () {
    var name = $(this).data('name');
    collapsedTSFailuresGroups[name] = !collapsedTSFailuresGroups[name];
    oSuitesFailuresTable.draw(false);
  } );

  // Datatables Test Cases Failures  - Begin
  DataTable.ext.errMode = 'none';
  var collapsedFailuresGroups = {};
  var oCaseFailuresTable = $('#test-cases-fails').DataTable( {
    paging: false
    // , colReorder: true
    , autoWidth: false
    // , fixedHeader: true
    , deferRender: false
    , dom: 'Bfrtip'
    , buttons: [
      {
        extend: 'copy'
        , title: 'Test cases that failed or error'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'print'
        , title: 'Test cases that failed or error'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'csv'
        , title: 'Test cases that failed or error'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> CSV'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'excelHtml5'
        , title: 'Test cases that failed or error'
        , text: '<i class="fas fa-download fa-sm text-white-50"></i> Excel'
        , className: 'shadow-sm'
        , exportOptions: {
            columns: '.printable'
        }
      }
    ]
    , order: [[0, 'asc']]
    , columns: [
      {
        data: 'platform'
        , className: 'printable'
      }
      , {
        data: 'name'
        , title: 'test suite name'
        , className: 'printable'
      }
      , {
        data: 'testcases_identifier'
        , title: 'test case name'
        , className: 'printable'
      }
      , {
        data: 'reason'
        , title: 'status / reason'
        , className: 'printable'
        , render: function(data, type, row) {
            let result = row.testcases_status == 'NaN' ? 'NA' : row.testcases_status;
            if (data != 'NaN')
              return `${row.testcases_status} / ${row.reason}`;
            else
              return `${result} / NA`;
          }
      }
      , {
        data: 'log'
        , visible: false
      }
      , {
        data: 'testcases_status'
        , title: 'logs'
        , className: 'text-center no-wrap actions'
        , orderable: false
        , render: function(data, type, row) {
            let response = ''
            if (server_mode) {
              response = `<div data-toggle="tooltip" title="Download handler log"> \
                <button type="button" class="btn btn-primary download-btn"
                  data-suite="${row.name}" \
                  data-platform="${row.platform}" \
                  data-filename="handler.log"><i class="fas fa-solid fa-download"></i> \
                  H</button></div> \
                <div data-toggle="tooltip" title="Download device log"> \
                  <button type="button" class="btn btn-primary download-btn" \
                  data-suite="${row.name}" \
                  data-platform="${row.platform}" \
                  data-filename="device.log"><i class="fas fa-solid fa-download"></i> \
                  D</button></div> \
                <div data-toggle="tooltip" title="Download build log"> \
                  <button type="button" class="btn btn-primary download-btn" \
                  data-suite="${row.name}" \
                  data-platform="${row.platform}" \
                  data-filename="device.log"><i class="fas fa-solid fa-download"></i> \
                  B</button></div>`;
            }

            if (row.log != 'NaN') {
              return `<div data-toggle="tooltip" title="Handler log from json"> \
                <button type="button" id="" class="btn btn-primary twister-log-btn" \
                  data-toggle="modal" data-target="#failuresModal" \
                  data-suite="${row.name}" \
                  data-reason="${row.reason}" \
                  data-platform="${row.platform}" \
                  data-body="${row.log}"> \
                TS log</button></div>` + response;
            }

            return '';
          }
      }
    ]
    , rowGroup: {
      dataSrc: 'platform'
      , startRender: function(rows, group) {
        var collapsed = !!collapsedFailuresGroups[group];

        rows.nodes().each(function(r) {
          r.style.display = collapsed ? '' : 'none';
        });

        // Add category name to the <tr>. NOTE: Hardcoded colspan
        return $('<tr/>')
          .append('<td colspan="5">' + group + ' (' + rows.count() + ')</td>')
          .attr('data-name', group)
          .toggleClass('collapsed', collapsed)
          .attr('id', 'tc-' + group);
      }
    }
    , initComplete: function() {
      $('#test-cases-fails_filter input').attr('id', 'test-cases-fails-search');
    }
  } );

  $('#test-cases-fails tbody').on('click', 'tr.dtrg-start', function () {
    var name = $(this).data('name');
    collapsedFailuresGroups[name] = !collapsedFailuresGroups[name];
    oCaseFailuresTable.draw(false);
  } );

  $('.download-btn').on('click', function () {
    var filename = $(this).data('filename');
    var test = $(this).data('suite');
    var platform = $(this).data('platform');

    window.location = `/download/${filename}?branch=${sessionStorage.getItem('branch')}&run_date=${sessionStorage.getItem('run_date_time')}&test_suite=${test}&platform=${platform}`;
  } );
} );
