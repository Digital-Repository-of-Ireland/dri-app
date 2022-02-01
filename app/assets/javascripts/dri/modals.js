$('#dri_citation_modal_id').ready(function() {
  // bind change event to select
  $('#dri_citation_options_id').bind('change', function () {
    var style = $(this).val(); // get selected value
    $(".dri_clipboard_text").hide();
    $('#citation-clipboard-button').attr('data-clipboard-target', "#citation-text-" + style);
    $('#citation-text-' + style).show();
  });
});
