// dri.js
//
// Some javascript to improve array handling in the edit and new audios forms

// When the document has loaded run these functions
$(document).ready(function() {
  add_text_field();
  destroy_text_field();
  add_person_fields();
  destroy_person_fields();
});

// Whenever an "add" link is clicked, a new text field is added to the bottom of the list 
add_text_field = function() {
    $('.add-text-field a').click(function() {
      var fieldset_name = $(this).parent().parent().attr('id');
      var model_name = $(this).attr('model-name');
      $(this).parent().before(  
      '<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" size="30" type="text" value=""> <a class="destructive">delete</a><br />');
      $(this).parent().siblings('a').last().click(function() {
        $(this).prev('input[type="text"]').remove();
        $(this).prev('br').remove();
        $(this).remove();
        return false;
      });
      return false;
    });
  }

// Remove the text field and the "delete" button whenever the "delete" link is clicked
destroy_text_field = function() {
    $('.destructive').click(function() {
      var fieldset_name = $(this).parent().attr('id');
      var model_name = $(this).attr('model-name');

      if ((fieldset_name == 'person_hash') && $(this).siblings('select').length > 1) {
        $(this).prev('input[type="text"]').remove();
        $(this).prev('select').remove();
        $(this).prev('br').remove();
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][type][" name="'+model_name+'['+fieldset_name+'][type][]" value="">');
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" value="">');
        $(this).remove();
      }
      else if (fieldset_name != 'person_hash') {
        $(this).prev('input[type="text"]').remove();
        $(this).prev('br').remove();
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" value="">');
        $(this).remove();
      }
      
      return false;
    });
}

add_person_fields = function() {
    $('.add-person-fields a').click(function() {
      var fieldset_name = $(this).parent().parent().attr('id');
      var model_name = $(this).attr('model-name')
      var previous_select = $(this).parent().siblings('select').last();
      $(this).parent().before(
      '<select id="'+model_name+'_'+fieldset_name+'][type][" selected="'+previous_select.val()+'" name="'+model_name+'['+fieldset_name+'][type][]">'+previous_select.html()+'</select> '+  
      '<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" size="30" type="text" value=""> <a class="destructive" model-name="'+model_name+'">delete</a><br />');
      $(this).parent().siblings('select').last().val(previous_select.val())
      $(this).parent().siblings('a').last().click(function() {
        var fieldset_name = $(this).parent().attr('id');
        var model_name = $(this).attr('model-name');

        if ($(this).siblings('select').length > 1) {
          var selected_value = $(this).prev('select').val();
          $(this).prev('input[type="text"]').remove();
          $(this).prev('select').remove();
          $(this).prev('br').remove();
          $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][type][" name="'+model_name+'['+fieldset_name+'][type][]" value="'+selected_value+'">');
          $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" value="">');
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

// Checkbox for adding an object to a collection in the edit tools sidebar
//= require blacklight/core
//= require blacklight/checkbox_submit
(function($) {
//change form submit toggle to checkbox
    Blacklight.do_collection_toggle_behavior = function() {
      $(Blacklight.do_collection_toggle_behavior.selector).bl_checkbox_submit({
          checked_label: "In Collection",
          unchecked_label: "Add to Collection",
          progress_label: "Saving...",
          //css_class is added to elements added, plus used for id base
          css_class: "toggle_collection"
      });
    };
    Blacklight.do_collection_toggle_behavior.selector = "form.collection_toggle";

$(document).ready(function() {
  Blacklight.do_collection_toggle_behavior();
});

})(jQuery);

