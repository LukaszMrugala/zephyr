(function($) {
  // Start of use strict
  "use strict";

  // Add query parameter to href in top menu
  $(document).ready(function() {
    const searchString = window.location.search;
    let paramsOld = new URLSearchParams(searchString);

    $('.navbar .menu a.btn').each(function() {
      var $this = $(this);
      const url = new URL($this.attr('href'), window.location);
      let paramsNew = url.searchParams;

      paramsOld.forEach((val, key) => {
        if (paramsNew.has(key))
          paramsNew[key] = val;
        else
          paramsNew.append(key, val);
      });

      let newUrl = new URL('?'+paramsNew, url);
      $this.attr('href', newUrl.href);
    });
  });

  // Disable Run date button if items of the menu no exist.
  const run_date_item = $('.dropdown-menu .dropdown-item.run_date');
  if (run_date_item.length == 0) {
    $('#runDateMenuButton').attr('disabled', 'disabled');
  }

  // Disable branch button if app works as desktop version or branch items no exist.
  let if_server_mode = Boolean(parseInt(sessionStorage.getItem('server_mode')));

  const branch_item = $('.dropdown-menu .dropdown-item.branch');
  if (!if_server_mode || branch_item.length == 0) {
    $('#branch-menu-dropdown-btn').attr('disabled', 'disabled');
  }

  // Generating Log Modal popup
  $('#failuresModal').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget); // Button that triggered the modal
    var suite_name = button.data('suite'); // Extract info from data-* attributes
    var reason = button.data('reason');
    var platform = button.data('platform');
    var body = button.data('body');
    // If necessary, you could initiate an AJAX request here (and then do the updating in a callback).
    // Update the modal's content. We'll use jQuery here, but you could use a data binding library or other methods instead.
    var modal = $(this);
    modal.find('.modal-title').html('<b>Fail log for test suite on platform: <i>' + platform + '.</i></b><br>Failed reason: <i>'
                                        + reason + '</i><br>Test suite name: <i>' + suite_name + '</i>');
    modal.find('.modal-body').html(body.replace(/&/g, "&amp;")
                                    .replace(/</g, "&lt;")
                                    .replace(/>/g, "&gt;")
                                    .replace(/"/g, "&quot;")
                                    .replace(/'/g, "&#39;")
                                    .replace(/(\\r\\n|\\r|\\n)/g, '<br>'));
  } );

})(jQuery);
// End of use strict
