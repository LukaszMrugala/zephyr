// Call the dataTables jQuery plugin
$(document).ready(function() {

// Datatables Components in Suites - Begin
  var collapsedSuiteGroups = {};
  let compCount = 0;
  let coverage = '';

  var oSuitesTable = $('#dTComponentSuites').DataTable( {
    dom: 'Bfrtip'
    , ordering: true
    , paging: false
    // fixedHeader: true,
    , buttons: [
      { extend: 'print',
        exportOptions: {
          columns: ':visible'
        }
      },
      { extend: 'csv'
        , exportOptions: {
          columns: ':visible'
        }
      }
      // , 'colvis'
    ]
    // , scrollCollapse: true
    // , scrollY: '700px'
    , order: [
      [1, 'asc']
    ]
    , columns: [
      {
        data: 'status'
        , visible: false
      }
      , {
        data: 'component'
        , title: 'component'
        // , className: 'comp-suites-th'
        , visible: true
      }
      , {
        data: 'sub_comp'
        , title: 'sub component'
        // , className: 'subcomp-suites-th'
        , visible: true
      }
      , {
        data: 'pass_rate'
        , title: 'pass rate'
        , width: '20%'
        , searchable: false
        , render: function(data) {
          var color = 'bg-success'
          if (data < 97) { color = ' bg-warning' }
          if (data < 90) { color = ' bg-danger' }
          return `<div class="progress">
            <div class="progress-bar ${color}" role="progressbar"
                style="width: ${data}%;" aria-valuenow="${data}" aria-valuemin="0"
                aria-valuemax="100"><span data-toggle="tooltip" title="passed / (passed + failed + error)">${data}%</span></div>
            </div>`;
        }
      }
      , {
        data: 'uniqe_suites'
        , title: 'unique suites'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
        , render: function(data) {
          return `<span data-toggle="tooltip" title="Count of test suites for this component">${data}</span>`;
        }
      }
      , {
        data: 'tests_count'
        , title: 'suite runs'
        , className: 'text-right'
        , width: '10%'
        , searchable: false
        , render: function(data) {
          return `<span data-toggle="tooltip" title="Count of run test suites marked as runnable for this component">${data}</span>`;
        }
      }
      , {
        data: 'passed'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'failed'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'error'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'skipped'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
    ]
    , rowGroup: {
      dataSrc: 'component'
      , startRender: function(rows, group) {
        var collapsed = !!collapsedSuiteGroups[group];
        let compSummary = new Array(0, 0, 0, 0, 0, 0, 0);

        compCount += 1;

        rows.nodes().each(function(r) {
          r.style.display = collapsed ? '' : 'none';

          compSummary[0] = 0;                               // pass rate
          compSummary[1] += Number(r.cells[3].textContent); // unique test cases
          compSummary[2] += Number(r.cells[4].textContent); // test cases
          compSummary[3] += Number(r.cells[5].textContent); // passed
          compSummary[4] += Number(r.cells[6].textContent); // failed
          compSummary[5] += Number(r.cells[7].textContent); // error
          compSummary[6] += Number(r.cells[8].textContent); // skipped
        });

        compSummary[0] = compSummary[3]/(compSummary[3]+compSummary[4]+compSummary[5])*100;

        let row_comp = '';
        compSummary.forEach(item => {
          row_comp += '<td>';

          if (row_comp == '<td>') {
            var color = 'bg-success'
            if (item < 97) { color = ' bg-warning' }
            if (item < 90) { color = ' bg-danger' }

            row_comp += `<div class="progress">
              <div class="progress-bar ${color}" role="progressbar"
                  style="width: ${item}%;" aria-valuenow="${item}" aria-valuemin="0"
                  aria-valuemax="100">${item.toFixed(2)}%</div>
              </div>`;
          }
          else {
            row_comp += item;
          }
          row_comp += '</td>';
        });

        // Add category name to the <tr>. NOTE: Hardcoded colspan
        return $('<tr/>')
          .append('<td colspan="2">' + group + ' (' + rows.count() + ')</td>' + row_comp)
          .attr('data-name', group)
          .toggleClass('collapsed', collapsed);
      }
    }
    , initComplete: function() {
      $('#dTComponentSuites_filter input').attr('id', 'dTComponentSuites_search');

        this.removeClass("no-footer");
        this.append($('<tfoot/>').append( $("#dTComponentSuites thead tr").clone() ));

    }
  } );

  $('#dTComponentSuites tbody').on('click', 'tr.dtrg-start', function() {
    var name = $(this).data('name');
    collapsedSuiteGroups[name] = !collapsedSuiteGroups[name];
    oSuitesTable.draw(false);
  } );

// Datatables Components in Cases - Begin
  var collapsedCaseGroups = {};
  compCount = 0;
  var oCasesTable = $('#dTComponentCases').DataTable( {
    ordering: false
    , paging: false
    , colReorder: true
    , autoWidth: false
    , fixedHeader: true
    , deferRender: false
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
      , {
        extend: 'excel'
        , exportOptions: {
          columns: ':visible'
        }
      }
      // , 'colvis'
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
        data: 'component'
        , title: 'component'
        , className: 'comp-cases-th'
      }
      , {
        data: 'sub_comp'
        , title: 'sub component'
        // , className: 'subcomp-cases-th'
      }
      , {
        data: 'pass_rate'
        , title: 'pass rate'
        , width: '15%'
        , searchable: false
        , render: function(data) {
          var color = 'bg-success'
          if (data < 97) { color = ' bg-warning' }
          if (data < 90) { color = ' bg-danger' }
          return `<div class="progress">
            <div class="progress-bar ${color}" role="progressbar"
                style="width: ${data}%;" aria-valuenow="${data}" aria-valuemin="0"
                aria-valuemax="100"><span data-toggle="tooltip" title="passed / (passed + failed + blocked + started + error)">${data}%</span></div>
            </div>`;
        }
      }
      , {
        data: 'uniqe_suites'
        , title: 'unique suites'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
        , render: function(data) {
          return `<span data-toggle="tooltip" title="Count of test cases for this component">${data}</span>`;
        }
      }
      , {
        data: 'unique_cases'
        , title: 'unique cases'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'tests_count'
        , title: 'case runs'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
        , render: function(data) {
          return `<span data-toggle="tooltip" title="Count of run test cases marked as runnable for this component">${data}</span>`;
        }
      }
      , {
        data: 'passed'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'failed'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'error'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'blocked'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'skipped'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
      , {
        data: 'started'
        , className: 'text-right'
        , width: '7%'
        , searchable: false
      }
    ]
    , rowGroup: {
      dataSrc: 'component'
      , startRender: function(rows, group) {
          var collapsed = !!collapsedCaseGroups[group];
          let compSummary = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

          compCount += 1;

          rows.nodes().each(function(r) {
            r.style.display = collapsed ? '' : 'none';

            compSummary[0] = 0;                                 // testcases_status
            compSummary[1] += Number(r.cells[3].textContent);   // pass rate
            compSummary[2] += Number(r.cells[4].textContent);   // unique suites
            compSummary[3] += Number(r.cells[5].textContent);   // unique cases
            compSummary[4] += Number(r.cells[6].textContent);   // passed
            compSummary[5] += Number(r.cells[7].textContent);   // failed
            compSummary[6] += Number(r.cells[8].textContent);   // error
            compSummary[7] += Number(r.cells[9].textContent);   // blocked
            compSummary[8] += Number(r.cells[10].textContent);  // skipped
            compSummary[9] += Number(r.cells[11].textContent);  // started
          });

          compSummary[0] = compSummary[4]/(compSummary[4]+compSummary[5]+compSummary[6]+compSummary[7]+compSummary[9])*100;

          let row_comp = '';
          compSummary.forEach(item => {
            row_comp += '<td>';

            if (row_comp == '<td>') {
              var color = 'bg-success'
              if (item < 97) { color = ' bg-warning' }
              if (item < 90) { color = ' bg-danger' }
              row_comp += `<div class="progress">
                <div class="progress-bar ${color}" role="progressbar"
                    style="width: ${item}%;" aria-valuenow="${item}" aria-valuemin="0"
                    aria-valuemax="100">${item.toFixed(2)}%</div>
                </div>`;
            }
            else {
              row_comp += item;
            }
            row_comp += '</td>'
          });

          // Add category name to the <tr>. NOTE: Hardcoded colspan
          return $('<tr/>')
            .append('<td colspan="2">' + group + ' (' + rows.count() + ')</td>' + row_comp)
            .attr('data-name', group)
            .toggleClass('collapsed', collapsed);
      }
    }
    , initComplete: function() {
        $('#dTComponentCases_filter input').attr('id', 'dTComponentCases_search');

        this.removeClass("no-footer");
        this.append($('<tfoot/>').append( $("#dTComponentCases thead tr").clone() ));
    }
  } );

  $('#dTComponentCases tbody').on('click', 'tr.dtrg-start', function() {
    var name = $(this).data('name');
    collapsedCaseGroups[name] = !collapsedCaseGroups[name];
    oCasesTable.draw(false);
  } );


  // Datatables Failures in Suites - Begin
  var collapsedFailuresGroups = {};
  var oFailuresSuitesTable = $('#dTFailuresSuites').DataTable( {
    ordering: false
    , paging: false
    , colReorder: true
    , autoWidth: false
    , fixedHeader: true
    , deferRender: false
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
      , {
        extend: 'excel'
        , exportOptions: {
          columns: ':visible'
        }
      }
      // , 'colvis'
    ]
    , order: [[0, 'asc']]
    , columns: [
      {
        data: 'component'
        , title: 'component'
        // , className: 'comp-cases-th'
      }
      , {
        data: 'sub_comp'
        , title: 'sub component'
      }
      , {
        data: 'name'
        , title: 'test suite name'
      }
      , {
        data: 'reason'
        , title: 'status - reason'
        , render: function(data, type, row) {
          return `${row.testcases_status} - ${row.reason}`;
        }
      }
      , {
        data: 'log'
        , visible: false
      }
      , {
        data: 'platform'
      }
      , {
        data: 'testcases_status'
        , title: 'logs'
        , class: 'text-center'
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
                <button type="button" id="" class="btn btn-primary"> \
                <span data-toggle="tooltip" title="Handlers log">H</span></button>`;
            else
              return 'NaN';
          }
      }
    ]
    , rowGroup: {
      dataSrc: 'component'
      , startRender: function(rows, group) {
        var collapsed = !!collapsedFailuresGroups[group];

        rows.nodes().each(function(r) {
          r.style.display = collapsed ? '' : 'none';
        });

        // Add category name to the <tr>. NOTE: Hardcoded colspan
        return $('<tr/>')
          .append('<td colspan="6">' + group + ' (' + rows.count() + ')</td>')
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
    oFailuresSuitesTable.draw(false);
  } );

  // Datatables Failures of Test Cases - Begin
  var collapsedFailuresGroups = {};
  var oFailuresCasesTable = $('#dTFailuresCases').DataTable( {
    ordering: false
    , paging: false
    , colReorder: true
    , autoWidth: false
    , fixedHeader: true
    , deferRender: false
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
      , {
        extend: 'excel'
        , exportOptions: {
          columns: ':visible'
        }
      }
      // , 'colvis'
    ]
    , order: [[0, 'asc']]
    , columns: [
      {
        data: 'component'
        , title: 'component'
        // , className: 'comp-cases-th'
      }
      , {
        data: 'sub_comp'
        , title: 'sub component'
      }
      , {
        data: 'name'
        , title: 'test case name'
      }
      , {
        data: 'reason'
        , title: 'status - reason'
        , render: function(data, type, row) {
          return `${row.testcases_status} - ${row.reason}`;
        }
      }
      , {
        data: 'log'
        , visible: false
      }
      , {
        data: 'platform'
      }
      , {
        data: 'testcases_status'
        , title: 'logs'
        , class: 'text-center'
        , orderable: false
        , render: function(data, type, row) {
            if (row.log != 'NaN')
              return `<button type="button" id="" class="btn btn-primary twister-log-btn" \
                data-toggle="modal" data-target="#failuresModal" \
                data-suite="${row.name}" \
                data-reason="${row.reason}" \
                data-platform="${row.platform}" \
                data-body="${row.log}"> \
                <span data-toggle="tooltip" title="Test suite log">TS</span></button> \
                <button type="button" class="btn btn-primary handlers-log-btn"> \
                <span data-toggle="tooltip" title="Handlers log">H</span></button>`;
            else
              return 'NaN';
          }
      }
    ]
    , rowGroup: {
      dataSrc: 'component'
      , startRender: function(rows, group) {
        var collapsed = !!collapsedFailuresGroups[group];

        rows.nodes().each(function(r) {
          r.style.display = collapsed ? '' : 'none';
        });

        // Add category name to the <tr>. NOTE: Hardcoded colspan
        return $('<tr/>')
          .append('<td colspan="6">' + group + ' (' + rows.count() + ')</td>')
          .attr('data-name', group)
          .toggleClass('collapsed', collapsed)
          .attr('id', 'comp-' + group);
      }
    }
    , initComplete: function() {
      $('#dTFailuresCases_filter input').attr('id', 'dTFailuresCases_search');
    }
  } );

  $('#dTFailuresCases tbody').on('click', 'tr.dtrg-start', function () {
    var name = $(this).data('name');
    collapsedFailuresGroups[name] = !collapsedFailuresGroups[name];
    oFailuresCasesTable.draw(false);
  } );

} );
