$(document).ready(function(){
  // clicked_highlighted = {
  //  'collections':     ['collections'],
  //  'sub_collections': ['collections', 'sub_collections'],
  //  'objects':         ['objects']
  // }

  // $.each(Object.keys(clicked_highlighted), function(i, key) {
  //  clicked_class = '#dri_browse_sort_tabs_' + key +'_id_no_reload a';
  //  highlighted_classes = clicked_highlighted[key];
  //  console.log(clicked_class);

  //  $(clicked_class).on('click', function() {
  //    console.log(clicked_class);
  //    $(clicked_class).addClass('selected');
  //    console.log(highlighted_classes);
  //    $.each(highlighted_classes, function(i, el) {
  //      console.log('rem: ' + '#dri_browse_sort_tabs_' + el + '_id_no_reload a');
  //      $('#dri_browse_sort_tabs_' + el + '_id_no_reload a').removeClass('selected');
  //    });
  //  });
  // });

  $('#dri_browse_sort_tabs_collections_id_no_reload a').on('click', function() {
    $('#dri_browse_sort_tabs_collections_id_no_reload a').addClass('selected');
    $('.advanced input[name=mode]').val('collections');
    $('.advanced input[name=show_subs]').val(false);

    $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').removeClass('selected');
    $('#dri_browse_sort_tabs_objects_id_no_reload a').removeClass('selected');
  });

  $('#dri_browse_sort_tabs_objects_id_no_reload a').on('click', function() {
    $('#dri_browse_sort_tabs_objects_id_no_reload a').addClass('selected');
    $('.advanced input[name=mode]').val('objects');
    $('.advanced input[name=show_subs]').val(false);

    $('#dri_browse_sort_tabs_collections_id_no_reload a').removeClass('selected');
    $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').removeClass('selected');
  });

  // sub-collections special case
  $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').on('click', function() {
    $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').addClass('selected');
    $('.advanced input[name=mode]').val('collections');
    $('.advanced input[name=show_subs]').val(true);

    $('#dri_browse_sort_tabs_collections_id_no_reload a').addClass('selected');
    $('#dri_browse_sort_tabs_objects_id_no_reload a').removeClass('selected');
  });

  function not_selected(class_name) {
    return $(class_name).hasClass('selected') != true;
  }

  // drop support for ie < 9 and use Array.every instead
  function array_all(arr, elem_callback) {
    $.each(arr, function(i, el) {
      if (elem_callback(el) != true) {
        return false;
      }
    });

    return true;
  }

  // if dropping support for ie, use urlsearchparams instead
  function get_url_param(name){
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    return (results == null) ? null : results[1] || 0;
  }

  var class_names = [
    '#dri_browse_sort_tabs_collections_id_no_reload a',
    '#dri_browse_sort_tabs_objects_id_no_reload a',
    '#dri_browse_sort_tabs_sub_collections_id_no_reload a'
  ];

  // if none are selected, check url params, select collections by default
  if (array_all(class_names, not_selected)) {
    var current_mode = get_url_param('mode');
    if (current_mode) { 
      $('#dri_browse_sort_tabs_' + current_mode + '_id_no_reload a').click();
    } else {
      $('#dri_browse_sort_tabs_collections_id_no_reload a').click();
    }
  }

});
