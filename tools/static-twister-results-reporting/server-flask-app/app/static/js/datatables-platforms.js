// Call the dataTables jQuery plugin
$(document).ready(function() {
  $('#dataTablePlatforms').DataTable( {
    pageLength: 50
    , scrollCollapse: true
    , scrollY: '700px'
    , dom: 'Bfrltip'
    , buttons: [
      {
        extend: 'print'
        , exportOptions: {
            columns: ':visible'
        }
      }
      , {
        extend: 'csv'
        , exportOptions: {
            columns: ':visible'
        }
      }
      // , 'colvis'
    ]
    , order: [
      [4, 'desc']
    ]
    , columns: [
      {
        data: 'testcases_status'
        , visible: false
      }
      , {
        data: 'platform'
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
        , title: 'pass rate'
        , searchable: false
        , render: function(data) {
            var color = 'bg-success'
            if (data < 97) { color = ' bg-warning' }
            if (data < 90) { color = ' bg-danger' }
            return `<div class="progress">
              <div class="progress-bar ${color}" role="progressbar"
                  style="width: ${data}%;" aria-valuenow="${data}" aria-valuemin="0"
                  aria-valuemax="100"><span>${Number(data)} %</span></div>
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
      // , { data: 'path',
      //   visible: false
      //   , searchable: false
      // }
    ]
  } );

  // Datatables Failures in Suites - Begin
  DataTable.ext.errMode = 'none';
  var collapsedFailuresGroups = {};
  var oFailuresTable = $('#dTFailuresSuites').DataTable( {
    paging: false
    // , colReorder: true
    , autoWidth: false
    // , fixedHeader: true
    , deferRender: false
    , dom: 'Bfrtip'
    , buttons: [
      {
        extend: 'print'
        , exportOptions: {
            columns: '.printable'
        }
      }
      , {
        extend: 'csv'
        , exportOptions: {
            columns: '.printable'
        }
      }
      // , 'colvis'
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
        , title: 'status'
        , className: 'printable'
        , render: function(data, type, row) {
            return `${row.testcases_status} - ${row.reason}`;
          }
      }
      , {
        data: 'log'
        , visible: false
      }
      , {
        data: 'testcases_status'
        , title: 'logs'
        , className: 'text-center no-wrap'
        , orderable: false
        , render: function(data, type, row) {
            if (row.log != 'NaN')
              return `<button type="button" id="" class="btn btn-primary" \
                  data-toggle="modal" data-target="#failuresModal" \
                  data-suite="${row.name}" \
                  data-reason="${row.reason}" \
                  data-platform="${row.platform}" \
                  data-body="${row.log}"> \
                  <span data-toggle="tooltip" title="Test suite log">TS</span></button> \
                  <button type="button" class="btn btn-primary download-btn"
                  data-suite="${row.name}" \
                  data-platform="${row.platform}" \
                  data-filename="handler.log"><i class="fas fa-solid fa-download"></i> \
                  <span data-toggle="tooltip" title="Download handler log">H</span></button> \
                  <button type="button" class="btn btn-primary download-btn"
                  data-suite="${row.name}" \
                  data-platform="${row.platform}" \
                  data-filename="device.log"><i class="fas fa-solid fa-download"></i> \
                  <span data-toggle="tooltip" title="Download device log">D</span></button> \
                  <button type="button" class="btn btn-primary download-btn"
                  data-suite="${row.name}" \
                  data-platform="${row.platform}" \
                  data-filename="device.log"><i class="fas fa-solid fa-download"></i> \
                  <span data-toggle="tooltip" title="Download build log">B</span></button> \
                `;
            else
              return 'NaN';
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
          .attr('id', 'comp-' + group);
      }
    }
    , initComplete: function() {
      $('#dTFailuresSuites_filter input').attr('id', 'dTFailuresSuites_search');
    }
  } );

  $('#dTFailuresSuites tbody').on('click', 'tr.dtrg-start', function () {
    var name = $(this).data('name');
    collapsedFailuresGroups[name] = !collapsedFailuresGroups[name];
    oFailuresTable.draw(false);
  } );

  $('.download-btn').on('click', function () {
    var filename = $(this).data('filename');
    var test = $(this).data('suite');
    var platform = $(this).data('platform');
    
    window.location = `/download/${filename}?branch=${localStorage.getItem('branch')}&run_date=${localStorage.getItem('run_date_time')}&test_suite=${test}&platform=${platform}`;
  } );
} );
