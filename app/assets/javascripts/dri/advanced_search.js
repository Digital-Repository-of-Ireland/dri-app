$(document).ready(function(){

  // if dropping support for ie, use urlsearchparams instead
  function get_url_param(name){
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    return (results == null) ? null : results[1] || 0;
  }

  // id that starts with dri_browse_sort_tabs and ends with no_reload
  var tab_selector = '[id^=dri_browse_sort_tabs][id$=no_reload]';

  // delegate event listener to parent to avoid no block scope bug
  $('#dri_browse_sort_tabs').delegate(tab_selector, 'click', function(){
    // unselect all tabs
    $(tab_selector + ' a').each(function(i, el) {
      $(el).removeClass('selected');
    });

    // always select current tab
    $(this).find('a').first().addClass('selected');
    var mode = this.id.replace('dri_browse_sort_tabs_', '')
                      .replace('_id_no_reload', '');

    // special subcollections case (highlight collections and sub_collections)
    if (mode == 'sub_collections') {
      $('#dri_browse_sort_tabs_collections_id_no_reload a').addClass('selected');
      $('.advanced input[name=mode]').val('collections');
      $('.advanced input[name=show_subs]').val(true);
    } else {
      $('.advanced input[name=mode]').val(mode);
      $('.advanced input[name=show_subs]').val(false);
    }
  });

  // if none are selected, check url params, select collections by default
  if ($(tab_selector).find('.selected').length < 1) {
    var current_mode = get_url_param('mode');
    var show_subs = get_url_param('show_subs');
    if (show_subs && show_subs == 'true' && current_mode == 'collections') {
      current_mode = 'sub_collections';
    }

    if (current_mode) {
      $('#dri_browse_sort_tabs_' + current_mode + '_id_no_reload a').click();
    } else {
      $('#dri_browse_sort_tabs_collections_id_no_reload a').click();
    }
  }
});
