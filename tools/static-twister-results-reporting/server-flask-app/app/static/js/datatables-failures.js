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
        , render: function(data, type, row) {
            if (row.log != 'NaN')
              return `<div class="float-left">${row.reason}</div><div class="float-right"><button type="button" class="btn btn-primary" \
                data-toggle="modal" data-target="#failuresModal" \
                data-suite="${row.name}" \
                data-reason="${row.reason}" \
                data-platform="" \
                data-body="${row.log}"> \
                <span data-toggle="tooltip" title="Test suite log">log</span></button> \
                <button type="button" class="btn btn-primary"> \
                <span data-toggle="tooltip" title="Handlers log">H</span></button></div>`;
            else
              return row.reason;
        }
      }
      , {
        data: 'log'
        , visible: false
      }
    ]
    , "language": {
      "emptyTable": "No fails, pass rate 100%"
    }
  } );
} );
