// Whenever an "add" link is clicked, a new text field is added to the bottom of the list
$(document).ready(function() { 
  $('.add-text-field a').click(function(e) { 
    var fieldset_id = $(this).parents('fieldset').attr('id');
    var model_name = $(this).attr('model-name');

    var element_to_add = ['description', 'rights'].includes(fieldset_id) ? 'textarea' : 'input';
    var nchildren = $("#"+fieldset_id+" > div > "+element_to_add).length;

    var remove_button = '<a class="destructive" model-name="batch">\
                          &nbsp; <i class="fa fa-times-circle"></i> Remove\
                        </a>';
    // var input_id = [model_name, fieldset_id, nchildren].join('_')+'][';
    var input_id = [model_name, fieldset_id].join('_')+'][';
    var input_name = model_name+'['+fieldset_id+'][]';

    e.preventDefault();
    var css_classes="edit span6";

    var autocomplete_elements = [
      'subject', 
      'coverage', 
      'geographical_coverage',
      'temporal_coverage'
    ];
    
    if ($.inArray(fieldset_id, autocomplete_elements) > -1) {
      css_classes += ' vocab-autocomplete';
    }

    if (element_to_add == 'textarea') {
      css_classes += ' dri-textarea';
      $("#"+fieldset_id+' .add-text-field').before(
        '<div>\
          <textarea class="' + css_classes + '" \
            id='+input_id+' name='+input_name+'>\
          </textarea>'+ remove_button +
        '</div>');
    } else {
      css_classes += ' dri-textfield';
      $("#"+fieldset_id+' .add-text-field').before(
        '<div>\
          <input class="' + css_classes + '" \
            id='+input_id+' name='+input_name+' \
            size="30" type="text" value=""/>'+remove_button+
        '</div>');
    }

    var added_element = $("#"+fieldset_id+" > div > "+element_to_add).last();
    // addChooseVocab('#' + fieldset_id); // remove old autocomplete vocab dropdown, add new one
    added_element.focus(); // focus on newly added input
  });

  $.each(['#subject', '#coverage', '#geographical_coverage', '#temporal_coverage'], function(index, id) {
    console.log(index, id);
    $(id).on('focusin', function() {
      console.log('focusin', id);
      addChooseVocab(id); // won't work, selecting dropdown will remove and readd dropdown
    });
    // .off not trigered when out of focus
    $(id).off('focusin', function() {
      console.log('off');
      $('#chose_vocab').remove();
      removeVocabAutocomplete();
    });
  });

  $('.dri_ingest_form').on('click','.destructive', function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');
    
    if(fieldset_id != 'roles') {
      $(this).parent('div').remove();
    }
  });

  $('.add-person-fields a').click(function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');
    var model_name = $(this).attr('model-name')
    var previous_select = $(this).parent().siblings('div').last().children('select');
    
    $(this).parent().before(
      '<div><select id="'+model_name+'_'+fieldset_id+'][type][" selected="'+previous_select.val()
      +'" name="'+model_name+'['+fieldset_id+'][type][]">'+previous_select.html()+'</select> '
      +'<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_id+'][name][" name="'
      +model_name+'['+fieldset_id+'][name][]" size="30" type="text" value="">  <a class="destructive" model-name="'
      +model_name+'">&nbsp;<i class="fa fa-times-circle"></i> Remove</a></div>'
    );

    $(this).parent().siblings('div').last().children('select').val(previous_select.val())
    
    $(this).parent().siblings('div').last().children('a').click(function(e) {
      e.preventDefault();
      $(this).parent('div').remove();
    });
  });

  // ensure at least one date is entered
  jQuery.validator.setDefaults({
   showErrors: function(errorMap, errorList) {
     // Clean up any tooltips for valid elements
     $.each(this.validElements(), function (index, element) {
       var $element = $(element);
       $element.data("title", "") // Clear the title - there is no error associated anymore
               .removeClass("dri_form_error")
               .tooltip("destroy");
      });
      // Create new tooltips for invalid elements
      $.each(errorList, function (index, error) {
        var $element = $(error.element);
        $element.tooltip("destroy") // Destroy any pre-existing tooltip so we can repopulate with new tooltip content
                .data("title", error.message)
                .addClass("dri_form_error")
                .tooltip(); // Create a new tooltip based on the error messsage we just set in the title
      });
    }, 
  });

  // ensure at least one date is entered
  $("#new_batch").validate({
    rules: {
      "batch[creation_date][]": { require_from_group: [1, ".date-group"] },
      "batch[published_date][]": { require_from_group: [1, ".date-group"] },
      "batch[date][]": { require_from_group: [1, ".date-group"] },
      "batch[creator][]": "required",
    },
    tooltip_options: {
      "batch[creation_date][]": { placement:'top' },
      "batch[published_date][]": { placement:'top' },
      "batch[date][]": { placement:'top' },
    },
  });

  $("#edit_batch").validate({
    rules: {
      "batch[creation_date][]": { require_from_group: [1, ".date-group"] },
      "batch[published_date][]": { require_from_group: [1, ".date-group"] },
      "batch[date][]": { require_from_group: [1, ".date-group"] },
      "batch[creator][]": "required",
    },
    tooltip_options: {
      "batch[creation_date][]": { placement:'top' },
      "batch[published_date][]": { placement:'top' },
      "batch[date][]": { placement:'top' },
    },
  });
});

function fileUploadHelper(thisObj) {
    $("#file_name").html(($(thisObj).val()).replace("C:\\fakepath\\", ""));
};

function coverImageFileUploadHelper(thisObj) {
    $("#cover_image").html(($(thisObj).val()).replace("C:\\fakepath\\", ""));
};
