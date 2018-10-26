function addVocabAutocomplete() {

  console.log('called add');
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
        url: endpoint + request.term,
        type: 'GET',
        dataType: 'json',
        complete: function (xhr, status) {
          var results = $.parseJSON(xhr.responseText);
          console.log('called autocompelte');
          // console.log(results);
          response(results);
        }
      });
    },
    select: function(request, response) {
      var current_vocab = $('#choose_vocab').find(':selected').text();
      // function that returns callback if it's possible to convert 
      // id to uri
      var getVocabUri = vocabNameToCallback(current_vocab);

      // if the vocab id can be converted to a uri
      // assign it to a data attribute on the current input
      if (getVocabUri) {
        var vocab_uri = getVocabUri(response.item.id);
        console.log(vocab_uri);
        var fieldset_id = $('#choose_vocab').parents('fieldset').attr('id');
        var model_name = $('#choose_vocab').siblings('.add-text-field')
                                           .children('a').attr('model-name');
        var hidden_uri_id = [model_name, fieldset_id].join('_')+'][uri][';
        var hidden_uri_name = model_name+'['+fieldset_id+'][][uri]';
        // add a hidden input with the vocab uri as the value
        // use a data attribute to validate that the value in the input
        // matches the label of the uri in the hidden input
        $(createHiddenInput(hidden_uri_id, hidden_uri_name, vocab_uri))
            .insertBefore($(this))
            .data('vocab-label', response.item.label);

        // add listener to remove the hidden input if it's no longer valid
        $(this).change(function() {
          // should be one hidden input and one non-hidden input per div
          var hidden_input = $(this).parent().find('input:hidden');
          var stored_label = hidden_input.data('vocab-label');
          var current_label = $(this).val();
          // if the hidden input exists, and the label doesn't match
          // remove the hidden input
          if (stored_label && current_label && (current_label != stored_label)) {
            console.log(current_label, stored_label);
            console.log("removing hidden input");
            $(hidden_input).remove();
          }
        });
      }
    },
    // TODO
    // issue with results not returning exact match
    // want to display since clicking should add uri to hidden element too in future
    // available in version 1.12.4? 
    // lookupFilter: function (suggestion, originalQuery, queryLowerCase) {
    //   console.log(suggestion.value.toLowerCase)
    //   return suggestion.value.toLowerCase().indexOf(queryLowerCase) === 0;
    // },
    autoFocus: true
  });
  return true;
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
    'geographical_coverage': 'Logaimn',
  }
  return mappings[id];
}

function vocabOptions() {
  return [
    ["Library of Congress", "/qa/search/loc/subjects?q="],
    ["Logaimn", "/qa/search/logainm/subjects?q="],
    ["OCLC FAST", "/qa/search/assign_fast/all?q="],
    ["Unesco", "/qa/search/unesco/subjects?q="],
    ["No authority (disable autocomplete)", "na"]
  ];
}

function vocabNameToCallback(text) {
  var mappings = {
    "Library of Congress": locIdToUri,
    "OCLC FAST": oclcFastIdToUri,
    'Unesco': function(id) {return id;} // unseco id is already uri
    // logainm id is uri, but all links data.logainm.ie/place so far are broken
  };

  return mappings[text];
}

function oclcFastIdToUri(id) {
  return 'http://fast.oclc.org/fast/' + id;
}

function locIdToUri(id) {
  return id.replace('info:lc', 'http://id.loc.gov')
}
