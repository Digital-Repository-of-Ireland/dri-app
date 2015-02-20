// dri.js
//
// Marc form JS

// When the document has loaded run these functions
$(document).ready(function() {
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
        var no_of_subfields = $(this).parent().parent().parent().parent().find('.subfield').length;
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
        var className = '.' + $(this).parent().attr('class').split(' ').join('.');
        var noOfDatafields = $(this).closest("fieldset").parent().find(className).length;
        if (noOfDatafields > 1) {
            $(this).closest("fieldset").remove();
            reindex_marc();
            return false;
        }
        else {
            $(this).closest("fieldset").find(".subfield-value").attr('value', '').val("");
            $(this).closest("fieldset").find(".ind1-tag").attr('value', '').val("");
            $(this).closest("fieldset").find(".ind2-tag").attr('value', '').val("");
        }
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
        var $clone = $(this).parent().parent().parent().parent().clone();
        $clone.find('.subfield-value').val('');
        var $target = $(this).closest("fieldset");
        $clone.insertAfter($target);
        reindex_marc();
    })
}

// Destroy .controlfield fieldset
destroy_marc_subfield = function() {
    $(".datafields").on("click", ".destroy-subfield", function(){
        var className = '.' + $(this).parent().parent().parent().parent().attr('class').split(' ').join('.');
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
    $("fieldset .controlfield > .subfield .ctrlfield-tag").each(function(index) {
        $(this).attr('id', 'batch_controlfield][' + index + '][controlfield_tag][').attr('name', 'batch[controlfield][' + index + '][controlfield_tag][]');
    });
    $("fieldset .controlfield > .subfield .ctrlfield-value").each(function(index) {
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
