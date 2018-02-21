// Whenever an "add" link is clicked, a new text field is added to the bottom of the list
$(document).ready(function() { 
  $('.add-text-field a').click(function(e){ 
    var fieldset_name = $(this).parents('fieldset').attr('id');
    var model_name = $(this).attr('model-name');

    e.preventDefault();
    if (fieldset_name == 'description'  || fieldset_name == 'rights') {
      $("#"+fieldset_name+' .add-text-field').before('<div><textarea class="edit span6 dri-textarea" id="'+model_name
                                  +'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name
                                  +'][]"></textarea> <a class="destructive" model-name="batch">&nbsp;<i class="fa fa-times-circle"></i> Remove</a></div>');
    } else {
      $("#"+fieldset_name+' .add-text-field').before('<div><input class="edit span6 dri-textfield" id="'+model_name
                                  +'_'+fieldset_name+'][" name="'+model_name+'['
                                  +fieldset_name+'][]" size="30" type="text" value=""/> <a class="destructive">&nbsp;<i class="fa fa-times-circle"></i> Remove</a></div>');
    }
  });

  $('.dri_ingest_form').on('click','.destructive', function(e){
    e.preventDefault();
    var fieldset_name = $(this).parents('fieldset').attr('id');
    
    if(fieldset_name != 'roles') {
      $(this).parent('div').remove();
    }
   });


  $('.add-person-fields a').click(function(e) {
    e.preventDefault();
    var fieldset_name = $(this).parents('fieldset').attr('id');
    var model_name = $(this).attr('model-name')
    var previous_select = $(this).parent().siblings('div').last().children('select');
    
    $(this).parent().before(
      '<div><select id="'+model_name+'_'+fieldset_name+'][type][" selected="'+previous_select.val()
      +'" name="'+model_name+'['+fieldset_name+'][type][]">'+previous_select.html()+'</select> '
      +'<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][name][" name="'
      +model_name+'['+fieldset_name+'][name][]" size="30" type="text" value="">  <a class="destructive" model-name="'
      +model_name+'">&nbsp;<i class="fa fa-times-circle"></i> Remove</a></div>'
    );

    $(this).parent().siblings('div').last().children('select').val(previous_select.val())
    
    $(this).parent().siblings('div').last().children('a').click(function(e) {
      e.preventDefault();
      $(this).parent('div').remove();
    });
  });
});

// ensure at least one date is entered
$(document).ready(function () {
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
});

// ensure at least one date is entered
$(document).ready(function () {
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
});

$(document).ready(function () {
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