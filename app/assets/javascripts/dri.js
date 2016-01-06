// dri.js
//
// Some javascript to improve array handling in the edit and new audios forms

// When the document has loaded run these functions
$(document).ready(function() {
    add_text_field();
    destroy_text_field();
    add_person_fields();
});

$(document).ready(function() {
    $('#dri_cookie_modal').modal({keyboard: false, backdrop: 'static'});
    $('.carousel').carousel('pause');
    $('.dri_help_popover_slow, #facets, #dri_social_media_links_id, #dri_sort_options_id, #dri_change_sort_view_id, #dri_page_options_id, #dri_facet_restrictions_links_id, #dri_pagination_nav_links_id, #dri_browse_sort_tabs_collections_id, #dri_browse_sort_tabs_objects_id').popover( {delay: { show: 1500, hide: 100 }} );
    $('.dri_help_popover').popover( {delay: { show: 100, hide: 100 }} );
    $('.dri_help_tooltip').tooltip( {delay: { show: 100, hide: 100 }} );
    $('a.dri_gallery').colorbox({rel:'group1', maxWidth:'95%', maxHeight:'95%'});
    if (navigator.userAgent.indexOf('iPhone') != -1 || navigator.userAgent.indexOf('Android') != -1) {
	    addEventListener("load", function() {
	            setTimeout(hideURLbar, 0);
	    }, false);
	}
});

function hideURLbar() {
	if (window.location.hash.indexOf('#') == -1) {
		window.scrollTo(0, 1);
	}
}

$(function(){
    // bind change event to select
    $('#dri_sort_options_id').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
    $('#dri_page_options_id').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
    $('#dri_can_edit_checkbox').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
});
  



// Whenever an "add" link is clicked, a new text field is added to the bottom of the list
add_text_field = function() {
    $('.add-text-field a').click(function() {
      var fieldset_name = $(this).parents('fieldset').attr('id');
      var model_name = $(this).attr('model-name');
      if (fieldset_name == 'description'  || fieldset_name == 'rights') {
	      $(this).parent().before(  
	      '<textarea class="edit span6 dri-textarea" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]"></textarea> <a class="destructive" model-name="batch">&nbsp;<i class="fa fa-times-circle"></i> Remove</a>');
	      $(this).parent().siblings('a').last().click(function(){
	        $(this).prev('textarea').remove();
	        $(this).remove();
	        return false;
	      });
      } else {
	      $(this).parent().before(  
	      '<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" size="30" type="text" value=""> <a class="destructive">&nbsp;<i class="fa fa-times-circle"></i> Remove</a>');
	      $(this).parent().siblings('a').last().click(function() {

	        $(this).prev('input[type="text"]').remove();
	        $(this).remove();
	        return false;
	      });
      }
      return false;
    });
  };

// Remove the text field and the "delete" button whenever the "delete" link is clicked
destroy_text_field = function() {
    $('.destructive').click(function() {
      var fieldset_name = $(this).parents('fieldset').attr('id');
      var model_name = $(this).attr('model-name');
      
      if (fieldset_name == 'description'  || fieldset_name == 'rights') {
        $(this).prevAll('textarea:first').remove();
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" value="">');
        $(this).remove();
      }
      else if ((fieldset_name == 'roles') && $(this).siblings('select').length > 1) {
        $(this).prevAll('input[type="text"]:first').remove();
        var selected_value = $(this).prev('select').val();
        $(this).prevAll('select:first').remove();
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][type][" name="'+model_name+'['+fieldset_name+'][type][]" value="'+selected_value+'">');
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][name][" name="'+model_name+'['+fieldset_name+'][name][]" value="">');
        $(this).remove();
      }
      else if (fieldset_name != 'roles') {
        $(this).prevAll('input[type="text"]:first').remove();
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" value="">');
        $(this).remove();
      }

      return false;
    });
};

add_person_fields = function() {
    $('.add-person-fields a').click(function() {
      var fieldset_name = $(this).parents('fieldset').attr('id');
      var model_name = $(this).attr('model-name')
      var previous_select = $(this).parent().siblings('select').last();
      $(this).parent().before(
      '<select id="'+model_name+'_'+fieldset_name+'][type][" selected="'+previous_select.val()+'" name="'+model_name+'['+fieldset_name+'][type][]">'+previous_select.html()+'</select> '+  
      '<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][name][" name="'+model_name+'['+fieldset_name+'][name][]" size="30" type="text" value="">  <a class="destructive" model-name="'+model_name+'">&nbsp;<i class="fa fa-times-circle"></i> Remove</a>');
      $(this).parent().siblings('select').last().val(previous_select.val())
      $(this).parent().siblings('a').last().click(function() {
        var fieldset_name = $(this).parent().attr('id');
        var model_name = $(this).attr('model-name');

        if ($(this).siblings('select').length > 1) {
          $(this).prev('input[type="text"]').remove();
          var selected_value = $(this).prev('select').val();
          $(this).prev('select').remove();
          $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][type][" name="'+model_name+'['+fieldset_name+'][type][]" value="'+selected_value+'">');
          $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][name][" name="'+model_name+'['+fieldset_name+'][name][]" value="">');
          $(this).remove();
        }
        return false;
      });
      return false;
    });
  }

// Adds audio player in asset display for audio file
$(document).ready(function() {  
    var audioSection = $('section#audio');  
    $('a.player').click(function() {  
        var audio = $('<audio>', {  
             controls : 'controls'  
        });  
        var url = $(this).attr('href');  
        $('<source>').attr('src', url).appendTo(audio);  
        audioSection.html(audio);  
        return false;  
    });
    
   
});

function fileUploadHelper(thisObj) {
    $("#file_name").html(($(thisObj).val()).replace("C:\\fakepath\\", ""));
};

function coverImageFileUploadHelper(thisObj) {
    $("#cover_image").html(($(thisObj).val()).replace("C:\\fakepath\\", ""));
};

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
    },
    tooltip_options: {
      "batch[creation_date][]": { placement:'top' },
      "batch[published_date][]": { placement:'top' },
      "batch[date][]": { placement:'top' },
    },
  });
});
