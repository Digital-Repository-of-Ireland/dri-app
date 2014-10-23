// dri.js
//
// Some javascript to improve array handling in the edit and new audios forms

// When the document has loaded run these functions
$(document).ready(function() {
    add_text_field();
    destroy_text_field();
    add_person_fields();
    destroy_marc_controlfield();
    add_marc_controlfield();
    add_marc_datafield();
    destroy_marc_datafield();
    add_marc_subfield();
    destroy_marc_subfield();
    reindex_marc();
});

// Destroy .controlfield fieldset
destroy_marc_controlfield = function() {
    $("#controlfields").on("click", ".destroy-ctrlfield", function(){
        var no_of_subfields = $(this).parent().parent().find('.subfield').length;
        if (no_of_subfields > 1) {
            $(this).closest("fieldset").remove();
            reindex_marc();
        }
        else{
            $(this).closest("fieldset").find('.ctrlfield-value').attr('value', '').val("");
        }
        return false;
    });
}

// Destroy .datafield fieldset
destroy_marc_datafield = function() {
    $(".datafields").on("click", ".destroy-datafield", function(){
        $(this).closest("fieldset").remove();
        reindex_marc();
        return false;
    });
}

// Add closest .controlfield
add_marc_controlfield = function() {
    $("#controlfields").on("click", ".add-ctrlfield", function() {
        var $clone = $(this).closest("fieldset").find(".subfield").first().clone();
        $clone.find('.ctrlfield-value').val('');
        var $target = $(this).closest("fieldset");
        $clone.appendTo($target);
        reindex_marc();
    })
}
// Add closest fieldset
add_marc_datafield = function() {
    $(".datafields").on("click", ".add-datafield", function() {
        var $clone = $(this).parent().clone();
        $clone.find('.subfield-value').val('');
        $clone.find('.ind1-tag').val('');
        $clone.find('.ind2-tag').val('');
        var $target = $(this).closest("fieldset");
        $clone.insertAfter($target);
        reindex_marc();
    })
}

// Add marc subfield
add_marc_subfield = function() {
    $(".datafields").on("click", ".add-df-subfield", function() {
        var $clone = $(this).parent().parent().clone();
        $clone.find('.subfield-value').val('');
        var $target = $(this).closest("fieldset");
        $clone.insertAfter($target);
        reindex_marc();
    })
}

// Destroy .controlfield fieldset
destroy_marc_subfield = function() {
    $(".datafields").on("click", ".destroy-subfield", function(){
        var className = '.' + $(this).parent().parent().attr('class').split(' ').join('.');
        var noOfSubfields = $(this).closest("fieldset").parent().find(className).length;
        if (noOfSubfields > 1) {
            $(this).closest("fieldset").remove();
            reindex_marc();
            return false;
        }
        else {
            $(this).closest("fieldset").find(".subfield-value").attr('value', '').val("");
        }
        return false;
    });
}


// Reindex marc subfields
reindex_marc = function() {
    $("fieldset .controlfield > .subfield > .ctrlfield-tag").each(function(index) {
        $(this).attr('id', 'batch_controlfield][' + index + '][controlfield_tag][').attr('name', 'batch[controlfield][' + index + '][controlfield_tag][]');
    });
    $("fieldset .controlfield > .subfield > .ctrlfield-value").each(function(index) {
        $(this).attr('id', 'batch_controlfield][' + index + '][controlfield_value][').attr('name', 'batch[controlfield][' + index + '][controlfield_value][]');
    });
    $("fieldset .datafield > .datafield-tag").each(function(index) {
        $(this).attr('id', 'batch_datafield][' + index + '][datafield_tag][').attr('name', 'batch[datafield][' + index + '][datafield_tag][]');
    });
    $("fieldset .datafield > .ind1-tag").each(function(index) {
        $(this).attr('id', 'batch_datafield][' + index + ']datafield_ind1][').attr('name', 'batch[datafield][' + index + ']datafield_ind1][]');
    });
    $("fieldset .datafield > .ind2-tag").each(function(index) {
        $(this).attr('id', 'batch_datafield][' + index + ']datafield_ind2][').attr('name', 'batch[datafield][' + index + ']datafield_ind2][]');
    });
    $("fieldset .datafield > .subfields").each(function(index) {
        $(this).find('.subfield-tag').each(function(i) {
            $(this).attr('id', 'batch_datafield]][' + index + '][subfield][' + i + '][subfield_code][').attr('name', 'batch[datafield]][' + index + '][subfield][' + i + '][subfield_code][]');
        });
        $(this).find('.subfield-value').each(function(i) {
            $(this).attr('id', 'batch_datafield]][' + index + '][subfield][' + i + '][subfield_value][').attr('name', 'batch[datafield]][' + index + '][subfield][' + i + '][subfield_value][]');
        });
    });
}

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

      if ((fieldset_name == 'roles') && $(this).siblings('select').length > 1) {

        $(this).prev('input[type="text"]').remove();
        var selected_value = $(this).prev('select').val();
        $(this).prev('select').remove();
        $(this).prev('br').remove();
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][type][" name="'+model_name+'['+fieldset_name+'][type][]" value="'+selected_value+'">');
        $(this).before('<input type="hidden" id="'+model_name+'_'+fieldset_name+'][name][" name="'+model_name+'['+fieldset_name+'][name][]" value="">');
        $(this).remove();
      }
      else if (fieldset_name != 'roles') {
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
      '<input class="edit span6 dri-textfield" id="'+model_name+'_'+fieldset_name+'][name][" name="'+model_name+'['+fieldset_name+'][name][]" size="30" type="text" value=""> <a class="destructive" model-name="'+model_name+'">delete</a><br />');
      $(this).parent().siblings('select').last().val(previous_select.val())
      $(this).parent().siblings('a').last().click(function() {
        var fieldset_name = $(this).parent().attr('id');
        var model_name = $(this).attr('model-name');

        if ($(this).siblings('select').length > 1) {
          $(this).prev('input[type="text"]').remove();
          var selected_value = $(this).prev('select').val();
          $(this).prev('select').remove();
          $(this).prev('br').remove();
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
