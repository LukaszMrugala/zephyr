(function($) {
  // Start of use strict
  "use strict";

  // Add query parameter to href in top menu
  $(document).ready(function() {
    const queryString = window.location.search;

    $('.navbar .menu a.btn').each(function() {
      var $this = $(this);
      var _href = $this.attr('href');

      $this.attr('href', _href + queryString);
    });
  });

  // Disable Run date button if items of the menu no exist.
  const item = $('.dropdown-menu .dropdown-item.run_date');
  if (item.length == 0) {
    $('#runDateMenuButton').attr('disabled', 'disabled');
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
