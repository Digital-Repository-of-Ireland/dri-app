function setOclcAutocomplete(selector='.dri-textfield') {
  $(selector).autocomplete({
    source: function (request, response) {
    // source: function (request={term: 'test'}, response) {
      $.ajax({
        // /qa/search/loc/subjects?q=
        // /qa/search/assign_fast/all?q=
        url: '/qa/search/loc/subjects?q=' + request.term + '&maximumRecords=5',
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

  // var options = {
  //   source: ['test', 'this', 'thing'],
  //   autoFocus: true
  // };

  // $(id).autocomplete(options);
}

$(document).ready(function($) {
  console.log('loaded vocabs');

  setOclcAutocomplete();
});
