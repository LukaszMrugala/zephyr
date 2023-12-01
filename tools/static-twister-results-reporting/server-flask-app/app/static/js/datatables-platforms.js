// Call the dataTables jQuery plugin
$(document).ready(function() {
  var oPlatformsTable = $('#dataTablePlatforms').DataTable( {
    pageLength: 50
    , scrollCollapse: true
    , scrollY: '700px'
    , order: [
      [4, 'desc']
    ]
    , columns: [
      { data: 'platform'
        , render: function(data, type, row) {
            queryString = window.location.search;
            const params = new URLSearchParams(queryString);
            params.set('p', data);
            return `<a href="/platform?${params.toString()}" title="${data}">${data}</a>`;
        }
        , title: 'platform name'
      }
      , { data: 'pass_rate'
        , title: 'pass rate'
        , searchable: false
        , render: function(data) {
            var color = 'bg-success'
            if (data < 97) { color = ' bg-warning' }
            if (data < 90) { color = ' bg-danger' }
            return `<div class="progress">
              <div class="progress-bar ${color}" role="progressbar"
                  style="width: ${data}%;" aria-valuenow="${data}" aria-valuemin="0"
                  aria-valuemax="100"><span>${Number(data)}</span></div>
              </div>`;
        }
      }
      , { data: 'test_cases'
        , title: 'test cases'
        , className: 'text-right'
        , searchable: false
        , render: function(data) {
            return `<span data-toggle="tooltip" title="Count of test cases marked as runnable for this platform">${data}</span>`;
        }
      }
      , { data: 'passed'
        , className: 'text-right'
        , searchable: false
      }
      , { data: 'failed'
        , className: 'text-right'
        , searchable: false
      }
      , { data: 'error'
        , className: 'text-right'
        , searchable: false
      }
      , { data: 'blocked'
        , className: 'text-right'
        , searchable: false
      }
      , { data: 'skipped'
        , className: 'text-right'
        , searchable: false
      }
      , { data: 'path', 
        visible: false
        , searchable: false
      }
    ]
  } );
} );
