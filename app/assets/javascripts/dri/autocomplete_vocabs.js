function addVocabAutocomplete() {
  var selector = '.vocab-autocomplete'
  var endpoint = $('#choose_vocab').find(':selected').val();
  if (endpoint === 'na') { 
    removeVocabAutocomplete();
    return false; 
  }
  // turn autocomplete back on
  $(selector).autocomplete({
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
      var current_vocab = $('#choose_vocab').find(':selected').text();
      var vocab_uri = vocabIdToUri(current_vocab, response.item.id);
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
  var fieldset_id = $('#choose_vocab').parents('fieldset').attr('id');
  var model_name = $('#choose_vocab').siblings('.add-text-field')
                                     .children('a').attr('model-name');
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

function handleMismatchedSavedUri(element) {
  var hidden_input = $(element).parent().find('input:hidden');
  var normal_input = $(element);
  var stored_label = hidden_input.data('vocab-label');
  var current_label = $(element).val();
  // if both inputs exists, and the labels don't match
  // remove the hidden input and revert back to non-link style
  if (stored_label && current_label && (current_label != stored_label)) {
    $(hidden_input).remove();
    $(element).css({'color':'black', 'text-decoration':'none'});
  }
}

function createHiddenInput(id, name, value='none') {
  return '<input id="'+id+'" name="'+name+'" type="hidden" value="'+value+'"/>';
}

function removeVocabAutocomplete() {
  var selector = '.vocab-autocomplete'
  $(selector).autocomplete({source: []});
}

function createChooseVocab() {
  var choose_vocab = document.createElement('select');
  choose_vocab.id = 'choose_vocab'
  var options = vocabOptions();

  options.forEach(function(arr){
    var option = document.createElement('option');
    option.text = arr[0];
    option.value = arr[1];
    choose_vocab.appendChild(option);
  });
  return choose_vocab;
}

function addChooseVocab(selector) {
  // add the dropdown menu
  $(createChooseVocab()).hide().appendTo($(selector)).slideDown('fast');

  var default_authority = $(selector).data('default-authority');
  if (default_authority) {
    $('#choose_vocab').val(
      '/qa/search/' + default_authority + '?q='
    );
  }

  // add autocomplete to relevant inputs
  addVocabAutocomplete();

  // update autcomplete endpoint when dropdown changes
  $('#choose_vocab').on('change', function(){
    addVocabAutocomplete();
  });
}

// Comment out this function to debug the dropdown
function removeChooseVocab() {
  $('#choose_vocab').slideUp('fast', function() {
    $(this).remove();
  });
}

function autoCompleteIds() {
  return ['#subject', '#coverage', '#geographical_coverage', '#temporal_coverage'];
}

function getDefaultAuthority(id) {
  var mappings = {
    'subject': 'Library of Congress',
    'coverage': 'Library of Congress', 
    'geographical_coverage': 'Logainm',
  }
  return mappings[id];
}

function vocabOptions() {
  return [
    ["Library of Congress", "/qa/search/loc/subjects?q="],
    ["Logainm", "/qa/search/logainm/subjects?q="],
    ["OCLC FAST", "/qa/search/assign_fast/all?q="],
    ["Unesco", "/qa/search/unesco/subjects?q="],
    ["No authority (disable autocomplete)", "na"]
  ];
}

function vocabIdToUri(vocab, id) {
  var mappings = {
    "Library of Congress": locIdToUri,
    "OCLC FAST": oclcFastIdToUri,
    "Unesco": function(v) {return v;}, // unseco id is already uri
    "Logainm": function(v) {return v;} // logainm id is uri, 
    // but all links data.logainm.ie/place so far are broken
    // e.g. http://data.logainm.ie/place/1391191 (Whitestown)
  };

  var conversion = mappings[vocab];
  // if you can convert the id to uri, return the uri
  if (conversion) {
    return conversion(id);
  } // implicit return undefined
}

function oclcFastIdToUri(id) {
  return 'http://fast.oclc.org/fast/' + id;
}

function locIdToUri(id) {
  return id.replace('info:lc', 'http://id.loc.gov')
}
