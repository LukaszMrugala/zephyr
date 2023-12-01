// Call the dataTables jQuery plugin
$(document).ready(function() {

  $('#dataTableFailures').DataTable( {
    pageLength: 25
    , scrollCollapse: true
    , scrollY: '600px'
    , columns: [
      { 
        data: 'name'
        , title: 'Test suite name (ts)'
        , render: function(data, type, row) {
          return `<span data-toggle="tooltip" title="Run ID: ${row.run_id}">${data}</span>`
        }
      }
      , {
        data: 'testcases_identifier'
        , title: 'Identifier (tc)'
      , }
      , { 
        data: 'run_id'
        , title: 'Run ID (ts)'
        , visible: false
      }
      , { 
        data: 'testcases_status'
        , title: 'Status (tc)'
      , }
      , { 
        data: 'testcases_reason'
        , title: 'Fail reason (tc)'
        , className: 'text-nowrap'
      }
      , { 
        data: 'execution_time'
        , title: 'Time (ts)'
        , className: 'text-right'
        , searchable: false
      }
      , { 
        data: 'status'
        , title: 'Status (ts)'
        , visible: false
      }
    ]
    , "language": {
      "emptyTable": "No fails, pass rate 100%"
    }
  } );

} );
