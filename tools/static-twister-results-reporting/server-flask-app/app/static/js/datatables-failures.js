// Call the dataTables jQuery plugin
$(document).ready(function() {

  // DataTables for showing failures on platform page
  $('#dataTableFailures').DataTable( {
    pageLength: 25
    , scrollCollapse: true
    , scrollY: '600px'
    , columns: [
      { 
        data: 'name'
        , title: 'TS name'
        , render: function(data, type, row) {
          return `<span data-toggle="tooltip" title="Run ID: ${row.run_id}">${data}</span>`;
        }
      }
      , {
        data: 'testcases_identifier'
        , title: 'TC identifier'
      }
      , { 
        data: 'testcases_status'
        , title: 'TC status'
      }
      , { 
        data: 'testcases_reason'
        , title: 'TC fail reason'
        , className: 'text-nowrap'
      }
      , { 
        data: 'execution_time'
        , title: 'TS execution time'
        , className: 'text-right'
        , searchable: false
      }
      , { 
        data: 'status'
        , title: 'TS status'
        , visible: false
      }
      , { 
        data: 'reason'
        , title: 'TS fail reason'
        , className: 'text-nowrap'
      }
      , {
        data: 'log'
        , title: 'logs'
        , className: 'text-center text-nowrap'
        , render: function(data, type, row) {
            let response = `<span data-toggle="tooltip" title="Download handler log"> \
                <button type="button" class="btn btn-primary download-btn"
                data-suite="${row.name}" \
                data-platform="${localStorage.getItem('platform')}" \
                data-filename="handler.log"><i class="fas fa-solid fa-download"></i>
                H</button></span> \
              <span data-toggle="tooltip" title="Download device log"> \
                <button type="button" class="btn btn-primary download-btn"
                data-suite="${row.name}" \
                data-platform="${localStorage.getItem('platform')}" \
                data-filename="device.log"><i class="fas fa-solid fa-download"></i> \
                D</button></span> \
              <span data-toggle="tooltip" title="Download build log"> \
                <button type="button" class="btn btn-primary download-btn"
                data-suite="${row.name}" \
                data-platform="${localStorage.getItem('platform')}" \
                data-filename="build.log"><i class="fas fa-solid fa-download"></i> \
                B</button></span>`;
      
            if (data != 'NaN') {
              return `<button type="button" id="" class="btn btn-primary twister-log-btn" \
                  data-toggle="modal" data-target="#failuresModal" \
                  data-suite="${row.name}" \
                  data-reason="${row.reason}" \
                  data-platform="${localStorage.getItem('platform')}" \
                  data-body="${data}"> \
                  <span data-toggle="tooltip" title="Test suite log">TS</span></button>` + response;
            } 
            else {
              return response;
            }
        }
      }
    ]
    , "language": {
      "emptyTable": "No fails, pass rate 100%"
    }
  } );

  $('.download-btn').on('click', function () {
    var filename = $(this).data('filename');
    var test = $(this).data('suite');
    var platform = $(this).data('platform');
    
    window.location = `/download/${filename}?branch=${localStorage.getItem('branch')}&run_date=${localStorage.getItem('run_date_time')}&test_suite=${test}&platform=${platform}`;
  } );

} );
