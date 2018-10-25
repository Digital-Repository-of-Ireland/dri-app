// Whenever an "add" link is clicked, a new text field is added to the bottom of the list
$(document).ready(function() { 
  $('.add-text-field a').click(function(e) { 
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');
    var model_name = $(this).attr('model-name');
    var new_elemenet_type = ['description', 'rights'].includes(fieldset_id) ? 
      'textarea' : 
      'input';
    var input_id = [model_name, fieldset_id].join('_')+'][';
    var input_name = model_name+'['+fieldset_id+'][]';
    var css_classes = "edit span6";
    // var default_authority = vocabOptions()[0][1];
    
    // add autocomplete class if necessary
    if ($.inArray('#' + fieldset_id, autoCompleteIds()) > -1) {
      css_classes += ' vocab-autocomplete';
      // include hidden input to send uri added by autocomplete to server
      // var hidden_id = [model_name, fieldset_id, 'uri'].join('_')+'][';
      // var hidden_name = model_name+'['+fieldset_id+'_uri][]';
      // $(createHiddenInput(hidden_id, hidden_name)).insertBefore($(this).parent());
    }

    var new_element_html = (new_elemenet_type == 'textarea') ?
      createTextArea(input_id, input_name, css_classes) :
      createTextInput(input_id, input_name, css_classes);

    $(new_element_html).hide().insertBefore(
      $(this).parent()
    ).slideDown('fast');

    var added_element = $("#"+fieldset_id+" > div > "+new_elemenet_type).last();
    addVocabAutocomplete(); // re-add autocomplete listeners to include new input
    added_element.focus(); // focus on newly added input
  });

  $.each(autoCompleteIds(), function(index, id) {
    $(id).on('focusin', function() {
      // addChooseVocab if it doesn't exist
      setTimeout(function() {
        if ($('#choose_vocab').length < 1) {
          addChooseVocab(id);
        }
      }, 500);
    });
    $(id).on('focusout', function() {
      // if id has no focused children
      // remove autocomplete and choose_vocab drop down
      setTimeout(function() {
        if (! $(id).find(':focus').length) {
          removeVocabAutocomplete();
          removeChooseVocab();
        }
      }, 100);
    });
  });

  $('.dri_ingest_form').on('click','.destructive', function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');
    
    // TODO
    // 1. make required fields generic? i.e. can't remove all inputs of type x
    if (fieldset_id === 'roles') {
      // ensure at least one role always exists
      // otherwise previous_select.html() will be empty 
      // and the next generated dropdown won't have any options
      if (numberOfRoles() > 1) {
        $(this).parent('div').slideUp('fast', function() {
          $(this).remove();
        });
      } else {
        alert('You must have at least one Contributor field')
      }
    } else {
      $(this).parent('div').slideUp('fast', function() {
        $(this).remove();
      });
    }
  });

  $('.add-person-fields a').click(function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');
    var model_name = $(this).attr('model-name');
    var previous_select = $(this).parent().siblings('div').last().children('select');
    var classes = "edit span6";

    var new_element_html = createPersonInput(fieldset_id, model_name, classes, previous_select);
    $(new_element_html).hide().insertBefore($(this).parent()).slideDown('fast');

    var added_element = $(this).parent().siblings('div').last();
    // set new dropdown selected value to the same as the parent select
    added_element.children('select').val(previous_select.val())
    // focus on the new input
    added_element.children('input').focus();    
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

function numberOfRoles() {
  return $('#roles').children('div').length;
}

function createRemoveButton(model='batch') {
  return '<a class="destructive" model-name="'+model+'">\
            &nbsp; <i class="fa fa-times-circle"></i> Remove\
          </a>';
}

function createTextArea(id, name, classes) {
  return '<div>\
            <textarea class="' + classes + ' dri-textarea " \
              id='+id+' name='+name+'>\
            </textarea>'+createRemoveButton()+
          '</div>';
}

function createTextInput(id, name, classes) {
  return '<div>\
            <input class="'+classes+' dri-textfield " \
              id='+id+' name='+name+' \
              size="30" type="text" value=""/>'+createRemoveButton()+
          '</div>';
}

// TODO 
// 1. move to ecma6 template strings
// 2. Check selected data-field needs to exist? (doesn't update, isn't on first element)
function createPersonInput(id, name, classes, previous_select) {
  return '<div>\
            <select id="'+name+'_'+id+'][type][" selected="'+previous_select.val()+
              '" name="'+name+'['+id+'][type][]">'+previous_select.html()+
            '</select> \
              <input class="'+classes+' dri-textfield " id="'+name+'_'+id+'][name][" name="'
              +name+'['+id+'][name][]" size="30" type="text" value=""/>'+createRemoveButton()+
          '</div>';
}
