// dri.js
//
// Some javascript to improve array handling in the edit and new audios forms

// When the document has loaded run these functions
$(document).ready(function() {
  add_text_field();
  destroy_text_field();
  // uploader_submit();
});

// Whenever an "add" link is clicked, a new text field is added to the bottom of the list 
add_text_field = function() {
    $('.add-text-field a').click(function() {
      var fieldset_name = $(this).parent().parent().attr('id');
      var model_name = $(this).attr('model-name');
      $(this).parent().before(  
      '<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][" name="'+model_name+'['+fieldset_name+'][]" size="30" type="text" value=""> <a class="destructive">Delete</a><br />');
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
      $(this).prev('input[type="text"]').remove();
      $(this).prev('br').remove();
      $(this).remove();
      return false;
    });
}

//uploader_submit = function() {
//  $('.uploader_submit').click(function() {
//     $('#file_uploader').submit();
//  });
//  $('.metadata_uploader_submit').click(function() {
//     $('#metadata_uploader').submit();
//  });
//}
