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
      console.log(endpoint + request.term);
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
  var options = [
    ["Library of Congress", "/qa/search/loc/subjects?q="],
    ["Logaimn", "/qa/search/logainm/subjects?q="],
    ["OCLC FAST", "/qa/search/assign_fast/all?q="],
    ["Unesco", "/qa/search/unesco/subjects?q="],
    ["No authority (disable autocomplete)", "na"]
  ];

  options.forEach(function(arr){
    var option = document.createElement('option');
    option.text = arr[0];
    option.value = arr[1];
    choose_vocab.appendChild(option);
  });
  return choose_vocab;
}

function addChooseVocab(selector) {
  // $('#choose_vocab').remove(); // remove the old choose vocab

  // add the new choose_vocab
  // $(selector).append(
  //   createChooseVocab(),
  // );
  $(createChooseVocab()).appendTo($(selector)).slideDown('slow');

  // add autocomplete
  addVocabAutocomplete();

  // update autcomplete endpoint when dropdown changes
  $('#choose_vocab').on('change', function(){
    addVocabAutocomplete();
  });

  return true;
}

function removeChooseVocab() {
  // $('#choose_vocab').fadeTo(300, 0.01, function(){ 
  //   $(this).slideUp(150, function() {
  //     $(this).remove(); 
  //   }); 
  // });
  $('#choose_vocab').remove();
}

function autoCompleteIds() {
  return ['#subject', '#coverage', '#geographical_coverage', '#temporal_coverage'];
}

function getDefaultAuthority(id) {
  var mappings = {
    'subject': 'loc',
    'coverage': 'loc', 
    'geographical_coverage': 'logainm',
    'temporal_coverage': ''
  }
  return mappings[id];
}


// TODO

// support these vocabs:
// 1. done //logainm.ie
// 2. done //unesco
// 3. done //(out of the box) // LOC
// 4. creator vocab: irish guidelines for indexing archives
// 5. type vocab:    dcmi vocab?

// ui:
// 1. support URI? e.g http://id.loc.gov/authorities/subjects/sh94007248.html
// from http://localhost:3000/qa/search/loc/subjects?q=easter+rising&maximumRecords=100
// by parsing id and replacing info:lc with http://id.loc.gov
// 2. done // add class for autocomplete
// 3. done // add class to subject and coverage
// 4. done // move extra <br>s above dropdown
// 5. move dropdown to the right so it's visible while suggestions are too?
// 6. done // handle case where no fields are selected but last used dropdown still exists
// 7. done // adding dropdown should be on focus, not on add new element
// 8. done // fix issue where immediately adding a new input doesn't create a new vocab dropdown
// because the old one still exists (due to set timeout handling overlap with focusout and focusin)
// 9. done // fix issue where dropdown is reset when adding an additional element

// issue: 
// localhost:3000//qa/search/loc/subjects?q=united%20state  returns
// localhost:3000//qa/search/loc/subjects?q=united%20stat   does not
// localhost:3000//qa/search/loc/subjects?q=united%20sta    does not
// localhost:3000//qa/search/loc/subjects?q=united%20st     returns
// &maxRecords param having no affect. possibly sufia only?

