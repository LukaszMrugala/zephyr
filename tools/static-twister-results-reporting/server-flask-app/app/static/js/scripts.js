(function($) {
  "use strict"; // Start of use strict

  // Add query parameter to href in top menu
  $(document).ready(function() {
    const queryString = window.location.search;

    $('.navbar .menu a.btn').each(function() {
      var $this = $(this);
      var _href = $this.attr('href');

      $this.attr('href', _href + queryString);
    });
  });

})(jQuery); // End of use strict
