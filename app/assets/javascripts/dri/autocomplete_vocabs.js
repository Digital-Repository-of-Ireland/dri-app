function setOclcAutocomplete(selector='.dri-textfield') {
  var endpoint = $('#choose_vocab').find(':selected').val();
  if (endpoint == 'na') { 
    $(selector).autocomplete({source: []}); // turn autocomplete off
    return false; 
  }
  $(selector).autocomplete({
    source: function (request, response) {
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

function addChooseVocab(selector='.dri-textfield') {
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
