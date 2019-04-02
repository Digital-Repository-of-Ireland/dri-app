$(document).ready(function(){
  // for each fieldset that has a choose-vocab-container in it
  $.each($('fieldset:has(.choose-vocab-container)'), function(_, fieldset) {
    var id = '#' + fieldset.id;
    $(id).on('focusin', function() {
      $(id + ' > .choose-vocab-container').slideDown('fast');
      addVocabAutocomplete(id);
    });
    $(id).on('focusout', function() {
      // if fieldset has no focused children, hide choose_vocab drop down
      // wait 100ms to stop hide / immediate unhide when changing focus to different element within the same fieldset
      setTimeout(function() {
        if ($(id).find(':focus').length < 1) {
          $(id + ' > .choose-vocab-container').slideUp('fast');
        }
      }, 100);
    });
  });

  // any time a vocab-dropdown changes, update the autocomplete endpoint
  $('.vocab-dropdown').each(function(){
    $(this).change(function(){
      addVocabAutocomplete($(this).parents('fieldset')[0].id);
    });
  });
});

function addVocabAutocomplete(id) {
  // select all visible text inputs in the current fieldset
  var input_selector = id + ' input[type="text"]:visible'
  var dropdown_selector = id + ' > .choose-vocab-container > .vocab-dropdown';
  var endpoint = $(dropdown_selector).find(':selected').val();
  if (endpoint === 'na') { 
    removeVocabAutocomplete(input_selector);
    return false; 
  }
  $(input_selector).autocomplete({
    source: function (request, response) {
      $.ajax({
        url: endpoint + request.term.toLowerCase(),
        type: 'GET',
        dataType: 'json',
        complete: function (xhr, status) {
          var results = $.parseJSON(xhr.responseText);
          response(results);
        }
      });
    },
    select: function(request, response) {
      var current_vocab = $(dropdown_selector).find(':selected').text();
      var vocab_uri = vocabIdToUri(current_vocab.trim(), response.item.id);
      // if a vocab uri was generated, save the uri to a hidden element
      if (vocab_uri) {
        saveUriInForm($(this), vocab_uri, response.item.label);
      }
    },
    autoFocus: true
  });
  return true;
}

// TODO refactor to use this instead of passing element down?
function saveUriInForm(element, vocab_uri, label) {
  var fieldset_id = $(element).parents('fieldset').attr('id');
  var model_name = $('#' + fieldset_id + ' .add-text-field a').attr('model-name');
  var hidden_uri_id = [model_name, fieldset_id].join('_')+'][';
  var hidden_uri_name = model_name+'['+fieldset_id+'][]';
  // add a hidden input with the vocab uri as the value
  // use a data attribute to validate that the value in the input
  // matches the label of the uri in the hidden input
  $(createHiddenInput(hidden_uri_id, hidden_uri_name, vocab_uri))
      .insertAfter($(element))
      .data('vocab-label', label);

  // make it clear this is a label for a link
  $(element).css({'color':'blue', 'text-decoration':'underline'});
  // remove the hidden input if the labels don't match
  $(element).change(function() {
    handleMismatchedSavedUri(element)
  });
}

// TODO run on all elements on form submit 
// focus out won't be triggered before form submits
function handleMismatchedSavedUri(element) {
  var hidden_input = $(element).parent().find('input:hidden');
  var normal_input = $(element);
  var stored_label = hidden_input.data('vocab-label');
  var current_label = $(element).val();
  // if both inputs exists, and the labels don't match
  // remove the hidden input and revert back to non-link style
  if (stored_label && current_label && (current_label !== stored_label)) {
    $(hidden_input).remove();
    $(element).css({'color':'black', 'text-decoration':'none'});
  }
}

function createHiddenInput(id, name, value) {
  return '<input id="'+id+'" name="'+name+'" type="hidden" value="'+value+'"/>';
}

function removeVocabAutocomplete(selector) {
  $(selector).autocomplete({source: []});
}

function vocabIdToUri(vocab, id) {
  var mappings = {
    "Library of Congress": locIdToUri,
    "OCLC FAST": oclcFastIdToUri,
    "Unesco": function(v) {return v;}, // unseco id is already uri
    "Logainm": function(v) {return v;}, // logainm id is uri, 
    // but all links data.logainm.ie/place so far are broken
    // e.g. http://data.logainm.ie/place/1391191 (Whitestown)
    // will be fixed by fct (facet browser) virtuoso add-on
    "NUTS3": function(v) {return v;}
  };

  var conversion = mappings[vocab];
  // if you can convert the id to uri, return the uri
  if (conversion) {
    return conversion(id);
  } // implicit return undefined
}

// function nuts3ToUri(id) {
//   id;
//   // // unofficial source, should not preserve
//   // return "https://tbed.org/eudemo/index.php?tablename=nuts_vw" + 
//   // "&function=details&where_field=nuts_code&where_value=" + id;
//   // // official source, but doesn't provide fullf resful service
//   // // map view available here
//   // https://ec.europa.eu/eurostat/cache/GISCO/distribution/v2/nuts/nuts-2016-units.html
//   // // json loaded e.g.
//   // https://ec.europa.eu/eurostat/cache/GISCO/distribution/v2/nuts/distribution/IE052-region-60m-4326-2016.geojson
// }

function oclcFastIdToUri(id) {
  return 'http://fast.oclc.org/fast/' + id;
}

function locIdToUri(id) {
  return id.replace('info:lc', 'http://id.loc.gov')
}
