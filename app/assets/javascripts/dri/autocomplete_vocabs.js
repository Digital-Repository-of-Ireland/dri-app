function setVocabAutocomplete(selector='.vocab-autocomplete') {
  var endpoint = $('#choose_vocab').find(':selected').val();
  console.log("called", selector, $(selector).length);
  if (endpoint === 'na') { 
    $(selector).autocomplete({source: []}); // turn autocomplete off
    return false; 
  }

  // turn autocomplete back on
  $(selector).autocomplete({
    source: function (request, response) {
      console.log(endpoint + request.term + '&maximumRecords=5');
      $.ajax({
        url: endpoint + request.term + '&maximumRecords=5',
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

function createChooseVocab() {
  var choose_vocab = document.createElement('select');
  choose_vocab.id = 'choose_vocab'
  var options = [
    ["Library of Congress", "/qa/search/loc/subjects?q="],
    ["OCLC FAST", "/qa/search/assign_fast/all?q="],
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
  $('#choose_vocab').remove(); // remove the old choose vocab

  // add the new choose_vocab
  $(selector).append(
    createChooseVocab(),
  );

  // add autocomplete
  setVocabAutocomplete();

  // update autcomplete endpoint when dropdown changes
  $('#choose_vocab').on('change', function(){
    setVocabAutocomplete();
  });

  return true;
}


// TODO

// support these vocabs:
// 1. logainm.ie
// 2. unesco
// 3. done (out of the box) // LOC
// 4. creator vocab: irish guidelines for indexing archives
// 5. type vocab:    dcmi vocab?

// ui:
// 1. support URI? e.g http://id.loc.gov/authorities/subjects/sh94007248.html
// from http://localhost:3000/qa/search/loc/subjects?q=easter+rising&maximumRecords=100
// by parsing id and replacing info:lc with http://id.loc.gov
// 2. done // add class for autocomplete
// 3. done // add class to subject and coverage
// 4. done // move extra <br>s above dropdown

// issue: 
// localhost:3000//qa/search/loc/subjects?q=united%20state  returns
// localhost:3000//qa/search/loc/subjects?q=united%20stat   does not
// localhost:3000//qa/search/loc/subjects?q=united%20sta    does not
// localhost:3000//qa/search/loc/subjects?q=united%20st     returns
// &maxRecords param having no affect. possibly sufia only?

