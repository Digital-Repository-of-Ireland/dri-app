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
        url: endpoint + request.term,
        type: 'GET',
        dataType: 'json',
        complete: function (xhr, status) {
          var results = $.parseJSON(xhr.responseText);
          response(results);
        }
      });
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
