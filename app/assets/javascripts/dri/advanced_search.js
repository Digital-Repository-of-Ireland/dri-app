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
    $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').removeClass('selected');
    $('#dri_browse_sort_tabs_objects_id_no_reload a').removeClass('selected');
  });

  $('#dri_browse_sort_tabs_objects_id_no_reload a').on('click', function() {
    $('#dri_browse_sort_tabs_objects_id_no_reload a').addClass('selected');
    $('#dri_browse_sort_tabs_collections_id_no_reload a').removeClass('selected');
    $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').removeClass('selected');
  });

  // sub-collections special case
  $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').on('click', function() {
    $('#dri_browse_sort_tabs_sub_collections_id_no_reload a').addClass('selected');
    $('#dri_browse_sort_tabs_collections_id_no_reload a').addClass('selected');
    $('#dri_browse_sort_tabs_objects_id_no_reload a').removeClass('selected');
  });

  function not_selected(class_name) {
    return $(class_name).hasClass('selected') != true;
  }

  // drop support for ie <= 9 and use Array.every
  function array_all(arr, elem_callback) {
    $.each(arr, function(i, el) {
      if (elem_callback(el) != true) {
        return false;
      }
    });

    return true;
  }

  // if none are selected, select collections
  class_names = [
    '#dri_browse_sort_tabs_collections_id_no_reload a',
    '#dri_browse_sort_tabs_objects_id_no_reload a',
    '#dri_browse_sort_tabs_sub_collections_id_no_reload a'
  ];

  if (array_all(class_names, not_selected)) {
    $('#dri_browse_sort_tabs_collections_id_no_reload a').click();
  }

});
