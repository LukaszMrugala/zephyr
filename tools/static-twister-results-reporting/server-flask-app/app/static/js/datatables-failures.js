// Call the dataTables jQuery plugin
$(document).ready(function() {
  let server_mode = Boolean(parseInt(sessionStorage.getItem('server_mode')));

  // DataTables for showing failures on platform page
  $('#dataTableFailures').DataTable( {
    paging: true
    , pageLength: 25
    , colReorder: true
    , autoWidth: false
    // , fixedHeader: true
    , deferRender: false
    , scrollCollapse: true
    // , scrollY: '600px'
    , scrollX: true
    , dom: 'Bfrltip'
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
      // , 'colvis'
    ]
    , columns: [
      {
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
        data: 'testcases_status'
        , title: 'status [tc]'
        , className: 'printable'
      }
      , {
        data: 'testcases_reason'
        , title: 'fail reason [tc]'
        , className: 'text-nowrap printable'
        , render: function(data, type, row) {
          return data == 'NaN' ? 'NA' : data;
      }
      }
      , {
        data: 'execution_time'
        , title: 'execution time [tc]'
        , className: 'text-right printable'
        , searchable: false
      }
      , {
        data: 'status'
        , title: 'status [ts]'
        , visible: false
      }
      , {
        data: 'reason'
        , title: 'fail reason [ts]'
        , className: 'text-nowrap printable'
        , render: function(data, type, row) {
            return data == 'NaN' ? 'NA' : data;
        }
      }
      , {
        data: 'log'
        , title: 'logs'
        , className: 'text-center text-nowrap actions'
        , render: function(data, type, row) {
            let response = ''
            if (server_mode) {
              response = `<div data-toggle="tooltip" title="Download handler log"> \
                  <button type="button" class="btn btn-primary download-btn"
                    data-suite="${row.name}" \
                    data-platform="${sessionStorage.getItem('platform')}" \
                    data-filename="handler.log"><i class="fas fa-solid fa-download"></i>
                  H</button></div> \
                <div data-toggle="tooltip" title="Download device log"> \
                  <button type="button" class="btn btn-primary download-btn"
                    data-suite="${row.name}" \
                    data-platform="${sessionStorage.getItem('platform')}" \
                    data-filename="device.log"><i class="fas fa-solid fa-download"></i> \
                  D</button></div> \
                <div data-toggle="tooltip" title="Download build log"> \
                  <button type="button" class="btn btn-primary download-btn"
                    data-suite="${row.name}" \
                    data-platform="${sessionStorage.getItem('platform')}" \
                    data-filename="build.log"><i class="fas fa-solid fa-download"></i> \
                  B</button></div>`;
            }

            if (data != 'NaN') {
              return `<div data-toggle="tooltip" title="Test suite log">
                <button type="button" id="" class="btn btn-primary twister-log-btn" \
                  data-toggle="modal" data-target="#failuresModal" \
                  data-suite="${row.name}" \
                  data-reason="${row.reason}" \
                  data-platform="${sessionStorage.getItem('platform')}" \
                  data-body="${data}"> \
                TS log</button></div>` + response;
            }

            return '';
        }
      }
      , {
        data: 'dut'
        , class: 'text-nowrap printable'
        , width: '10%'
        , render: function(data, type, row) {
          return data == 'NaN' ? 'NA' : data;
      }
      }
    ]
    , "language": {
      "emptyTable": "No fails, pass rate 100%"
    }
    , initComplete: function() {
      $('#dataTableFailures_filter input').attr('id', 'dataTableFailures-search');
    }
  } );

  $('.download-btn').on('click', function () {
    var filename = $(this).data('filename');
    var test = $(this).data('suite');
    var platform = $(this).data('platform');

    window.location = `/download/${filename}?branch=${sessionStorage.getItem('branch')}&run_date=${sessionStorage.getItem('run_date_time')}&test_suite=${test}&platform=${platform}`;
  } );

} );
