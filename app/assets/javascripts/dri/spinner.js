$(document).ready(function() {
  var opts = {
  lines: 13, length: 20, width: 10, radius: 30, corners: 1,
  rotate: 0, direction: 1, color: '#000', speed: 1,
  shadow: false, className: 'spinner', zIndex: 2e9
  };

  var target = document.getElementById('dri_loading_spinner_center');
  var spinner = new Spinner(opts).spin(target);

} );