
// Whenever an "add" link is clicked, a new text field is added to the bottom of the list
$(document).ready(function() {
  $('.add-text-field a').click(function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');

    // do not add if current is empty
    if (typeof $("#"+fieldset_id+" > div > .edit").last().val() != 'undefined' &&
        $("#"+fieldset_id+" > div > .edit").last().val().trim() === ''){
      return;
    }

    var model_name = $(this).attr('model-name');
    var new_element_type = $(this).data('input-type');
    var label = $(this).data('label');
    var input_id = [model_name, fieldset_id].join('_');
    var input_name = model_name+'['+fieldset_id+'][]';
    var count = $('[name="' + input_name + '"]').length + 1;
    var new_element_html = (new_element_type == 'textarea') ?
      createTextArea(input_id + "_" + count, input_name, label) :
      createTextInput(input_id + "_" + count, input_name, label);

    $(new_element_html).hide().insertBefore(
      $(this).parent()
    ).slideDown('fast');

    var added_element = $("#"+fieldset_id+" > div > "+new_element_type).last();
    added_element.focus(); // focus on newly added input
  });

  $('.dri_ingest_form').on('click','.destructive', function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');
    if ($("#"+fieldset_id+" > div > .edit").length > 1
        || form_action == "create") {
      $(this).parent('div').slideUp('fast', function() {
        $(this).remove();
      });
    } else {
      $(this).parent('div').children('.edit').val("");
    }
  });

  $('.add-person-fields a').click(function(e) {
    e.preventDefault();
    var fieldset_id = $(this).parents('fieldset').attr('id');

    if (typeof $("#"+fieldset_id+" > div > .edit").last().val() != 'undefined' &&
        $("#"+fieldset_id+" > div > .edit").last().val().trim() === ''){
      return;
    }

    var model_name = $(this).attr('model-name');
    var previous_select = $(this).parent().siblings('div').last().children('select');

    var new_element_html = createPersonInput(fieldset_id, model_name, previous_select);
    $(new_element_html).hide().insertBefore($(this).parent()).slideDown('fast');

    var added_element = $(this).parent().siblings('div').last();
    // set new dropdown selected value to the same as the parent select
    if (typeof previous_select.val() != "undefined") {
      added_element.children('select').val(previous_select.val());
    }
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
               .tooltip("dispose");
      });
      // Create new tooltips for invalid elements
      $.each(errorList, function (index, error) {
        var $element = $(error.element);
        $element.tooltip("dispose") // Destroy any pre-existing tooltip so we can repopulate with new tooltip content
                .data("title", error.message)
                .addClass("dri_form_error")
                .tooltip(); // Create a new tooltip based on the error messsage we just set in the title
      });
    },
  });

  // ensure at least one date is entered
  $("#new_digital_object").validate({
    rules: {
      "digital_object[creation_date][]": { require_from_group: [1, ".date-group"] },
      "digital_object[published_date][]": { require_from_group: [1, ".date-group"] },
      "digital_object[date][]": { require_from_group: [1, ".date-group"] },
      "digital_object[creator][]": "required",
    },
    tooltip_options: {
      "digital_object[creation_date][]": { placement:'top' },
      "digital_object[published_date][]": { placement:'top' },
      "digital_object[date][]": { placement:'top' },
    },
  });

  $("#edit_digital_object").validate({
    rules: {
      "digital_object[creation_date][]": { require_from_group: [1, ".date-group"] },
      "digital_object[published_date][]": { require_from_group: [1, ".date-group"] },
      "digital_object[date][]": { require_from_group: [1, ".date-group"] },
      "digital_object[creator][]": "required",
    },
    tooltip_options: {
      "digital_object[creation_date][]": { placement:'top' },
      "digital_object[published_date][]": { placement:'top' },
      "digital_object[date][]": { placement:'top' },
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

function createRemoveButton(model) {
  return '<a class="destructive" model-name="'+model+'">\
            &nbsp; <i class="fa fa-times-circle"></i> Remove\
          </a>';
}

function createTextArea(id, name, label) {
  return '<div>\
            <label for="' + id + '" class="visually-hidden">' + label + '</label>\
            <textarea class="edit span6 dri-textarea " \
              id='+id+' name='+name+'>\
            </textarea>'+createRemoveButton('batch')+
          '</div>';
}

function createTextInput(id, name, label) {
  return '<div>\
            <label for="' + id + '" class="visually-hidden">' + label + '</label>\
            <input class="edit span6 dri-textfield " \
              id='+id+' name='+name+' \
              size="30" type="text" value=""/>'+createRemoveButton('batch')+
          '</div>';
}

// TODO
// 1. move to ecma6 template strings
// 2. Check selected data-field needs to exist? (doesn't update, isn't on first element)
function createPersonInput(id, name, previous_select) {
  if (typeof previous_select.html() == "undefined") {
    roles_options = roles;
  } else {
    roles_options = previous_select.html();
  }
  var count = $('[name="' + name + '[' + id + '][type][]"').length + 1;

  return '<div>\
            <label class="visually-hidden" for="'+name+'_'+id+'_type_'+count+'">Role</label> \
            <select id="'+name+'_'+id+'_type_'+count+
              '" name="'+name+'['+id+'][type][]">'+roles_options+
            '</select> \
            <label class="visually-hidden" for="'+name+'_'+id+'_name_' + count +'">Name</label> \
              <input class="edit span6 dri-textfield " id="'+name+'_'+id+'_name_' + count +'" name="'
              +name+'['+id+'][name][]" size="30" type="text" value=""/>'+createRemoveButton('batch')+
          '</div>';
}

function clearAdvancedForm(form_id) {
  // remove text from text inputs
  $(form_id).find('input[type=text]').val('').end();
  // reset search operator to 'all'
  $(form_id + ' select#op').val('AND');
}
