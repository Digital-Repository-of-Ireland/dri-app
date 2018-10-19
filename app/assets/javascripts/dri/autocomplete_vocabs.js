function setOclcAutocomplete(selector='.vocab-autocomplete') {
  var endpoint = $('#choose_vocab').find(':selected').val();
  if (endpoint == 'na') { 
    $(selector).autocomplete({source: []}); // turn autocomplete off
    return false; 
  }
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

function addChooseVocab(selector='.dri_ingest_form_container') {
  var to_insert_beside = $(selector)[0];
  if (to_insert_beside === undefined) {
    return false;
  }
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

  to_insert_beside.before(
    choose_vocab,
    document.createElement('br')
  );
  return true;
}

// wait til doc is ready
$(function () {
  addChooseVocab();
  setOclcAutocomplete(); // set autocomplete when page loads
  $('#choose_vocab').change(function() {
    setOclcAutocomplete(); // update autocomplete using value of select option
  });
});

// TODO

// support these vocabs:
// logainm.ie
// unesco
// LOC
// creator vocab: irish guidelines for indexing archives
// type vocab:    dcmi vocab?

// support URI? e.g http://id.loc.gov/authorities/subjects/sh94007248.html
// from http://localhost:3000/qa/search/loc/subjects?q=easter+rising&maximumRecords=100
// by parsing id and replacing info:lc with http://id.loc.gov
// add class for autocomplete
// add class to subject and coverage


