$('#dri_timeline_id').ready(function() {
  var timelineData = $('#dri_timeline_id').data('timeline-data');
  var currentPage = $('#dri_timeline_id').data('current-page');
  var totalPages = $('#dri_timeline_id').data('total-pages');
  
  var index;
  var tlwidth = $('#dri_timeline_id').width();

  var additionalOptions = {
    width: tlwidth,
  }
  var timeline = new TL.Timeline('time_line', timelineData);   

  timeline.on("nav_next", function(data) {
    var slides = data.target._slides;

    for (var i = 0; i < slides.length; i++) {
      if (slides[i].active == true) {
        index = i;
      }
    }

    if (index == slides.length - 1 && currentPage < totalPages) {
      if ($( ".tl-slidenav-next .tl-slidenav-title").html() == "More results") {
        query = setUrlEncodedKey("tl_page", currentPage + 1);
        query = setUrlEncodedKey("direction", "forward", query);
        
        $(location).attr('href', query);
      } else {
        $( ".tl-slidenav-next" ).show();
        $( ".tl-slidenav-next .tl-slidenav-title").html("More results");
        $( ".tl-slidenav-next .tl-slidenav-description").html("Load more timeline objects.");
      }
    }
  });

  timeline.on("nav_previous", function(data) {
    var slides = data.target._slides;

    for (var i = 0; i < slides.length; i++) {
      if (slides[i].active == true) {
        index = i;
      }
    }
    if (currentPage > 1 && index == 0) {
      if ($( ".tl-slidenav-previous .tl-slidenav-title").html() == "Previous results") {
        query = setUrlEncodedKey("tl_page", currentPage - 1);
        query = setUrlEncodedKey("direction", "back", query);

        $(location).attr('href', query);
      } else {
        $( ".tl-slidenav-previous" ).show();
        $( ".tl-slidenav-previous .tl-slidenav-title").html("Previous results");
        $( ".tl-slidenav-previous .tl-slidenav-description").html("Load previous timeline objects.");
      }
    }
  });

  $(window).load(function() {
    direction = getUrlEncodedKey("direction");
    if ( direction == "forward") {
      $( ".tl-slidenav-previous" ).trigger("click");
    } else if (direction == "back") {
      timeline.goToEnd();
      $( ".tl-slidenav-next" ).trigger("click");
    }
  })

  getUrlEncodedKey = function(key, query) {
    if (!query)
        query = window.location.search;    
    var re = new RegExp("[?|&]" + key + "=(.*?)&");
    var matches = re.exec(query + "&");
    if (!matches || matches.length < 2)
        return "";
    return decodeURIComponent(matches[1].replace("+", " "));
  }

  setUrlEncodedKey = function(key, value, query) {
    query = query || window.location.search;
    var q = query + "&";
    var re = new RegExp("[?|&]" + key + "=.*?&");
    if (!re.test(q))
        q += key + "=" + encodeURI(value);
    else
        q = q.replace(re, "&" + key + "=" + encodeURIComponent(value) + "&");
        q = q.trimStart("&").trimEnd("&");
    return q[0]=="?" ? q : q = "?" + q;
  }

  String.prototype.trimEnd = function(c) {
    if (c)        
      return this.replace(new RegExp(c.escapeRegExp() + "*$"), '');
    return this.replace(/\s+$/, '');
  }
  String.prototype.trimStart = function(c) {
    if (c)
      return this.replace(new RegExp("^" + c.escapeRegExp() + "*"), '');
    return this.replace(/^\s+/, '');
  }

  String.prototype.escapeRegExp = function() {
    return this.replace(/[.*+?^${}()|[\]\/\\]/g, "\\$0");
  };
});