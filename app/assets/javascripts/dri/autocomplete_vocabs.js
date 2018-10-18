function setOclcAutocomplete(selector='.dri-textfield') {
  var endpoint = $('#toggle_vocab').find(':selected').val();
  if (endpoint == 'na') { 
    $(selector).autocomplete({source: []});
    return false; 
  }
  console.log(endpoint);
  $(selector).autocomplete({
    source: function (request, response) {
      $.ajax({
        // /qa/search/loc/subjects?q=
        // /qa/search/assign_fast/all?q=
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
  })
}

function addVocabToggle(selector='.dri-textfield') {
  var to_insert_beside = $(selector)[0]
  if (to_insert_beside === undefined) {
    return false;
  } else {
    var toggle_vocab = document.createElement('select');
    toggle_vocab.id = 'toggle_vocab'
    toggle_vocab.onchange = setOclcAutocomplete
    var options = [
      ["Library of Congress", "/qa/search/loc/subjects?q="],
      ["OCLC FAST", "/qa/search/assign_fast/all?q="],
      ["No authority (disable autocomplete)", "na"]
    ];

    options.forEach(function(arr){
      var option = document.createElement('option');
      option.text = arr[0];
      option.value = arr[1];
      toggle_vocab.appendChild(option);
    });

    // let m = new Map([
    //   ["Library of Congress", "/qa/search/loc/subjects?q="],
    //   ["OCLC FAST", "/qa/search/assign_fast/all?q="],
    //   ["No authority (disable autocomplete)", "na"]
    // ]);

    // m.forEach((key, value) => {
    //   let option = document.createElement('option');
    //   option.text = key;
    //   option.value = value;
    //   toggle_vocab.appendChild(option);
    // });

    to_insert_beside.before(
      // '\
      // <select>\
      //    <option value="/qa/search/loc/subjects?q=">Library of Congress</option>\
      //    <option value="/qa/search/assign_fast/all?q=">OCLC FAST</option>\
      //    <option value="na">No authority (disable autocomplete)</option>\
      // </select>\
      // '
      toggle_vocab,
      document.createElement('br')
    );
  }
  return true;
}

$(document).ready(function($) {
  if (addVocabToggle()) {
    setOclcAutocomplete();
  }
});
