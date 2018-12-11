// dri.js
//

$(document).ready(function() {
    $('#dri_cookie_modal').modal({keyboard: false, backdrop: 'static'});
    $('.carousel').carousel('pause');
    $('.dri_help_popover_slow, #facets, #dri_social_media_links_id, #dri_sort_options_id, #dri_change_sort_view_id, #dri_page_options_id, #dri_facet_restrictions_links_id, #dri_pagination_nav_links_id, #dri_browse_sort_tabs_collections_id, #dri_browse_sort_tabs_objects_id, #dri_tlfield_options_id').popover( {delay: { show: 1500, hide: 100 }} );
    $('.dri_help_popover').popover( {delay: { show: 100, hide: 100 }} );
    $('.dri_help_tooltip').tooltip( {delay: { show: 100, hide: 100 }} );
    $('a.dri_gallery').colorbox({rel:'group1', maxWidth:'95%', maxHeight:'95%', photo: true});
    if (navigator.userAgent.indexOf('iPhone') != -1 || navigator.userAgent.indexOf('Android') != -1) {
	    addEventListener("load", function() {
	            setTimeout(hideURLbar, 0);
	    }, false);
	  }
});

function hideURLbar() {
	if (window.location.hash.indexOf('#') == -1) {
		window.scrollTo(0, 1);
	}
}

$(function(){
    // bind change event to select
    $('#dri_sort_options_id').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
    // bind change event to select
    $('#dri_tlfield_options_id').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
    $('#dri_page_options_id').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
    $('#dri_can_edit_checkbox').bind('change', function () {
        var url = $(this).val(); // get selected value
        if (url) { // require a URL
            window.location = url; // redirect
        }
        return false;
    });
});

$(document).ready(function () {
    $('a.dri_iiif').colorbox({
        height:'80%' ,
        width:'80%',
        inline: true
    });

    $(window).resize(function(){
      $.colorbox.resize({
        width: '80%',
        height: '80%'
      });
    });
});

$(document).ready(function () {
$('#dri_pdf_viewer_modal_id .modal-content').resizable({
      alsoResize: ".modal-body",
      minHeight: 300,
      minWidth: 300
    });
    $('#dri_pdf_viewer_modal_id .modal-content').draggable({handle: "#dri_pdf_header"});

    $('#dri_pdf_viewer_modal_id').on('show.bs.modal', function() {
      $(this).find('.modal-body').css({
        'max-height': '100%'
      });
    });
});

$(document).on("click", ".view_pdf", function () {
     var pdf = $(this).data('source');
     var title = $(this).data('title');
     $("#dri_pdf_viewer_modal_id .modal-title").html(title);
     $("#dri_pdf_viewer_modal_id .modal-body").html("<object data=" + pdf + " type=\"application/pdf\" width=\"100%\" height=\"100%\"/>");
});

// function to display csv surrogate in a table
$(document).ready(function() {

    d3.csv($("#dri_tabular_surrogate_display").data('surrogate'), function(tabularData) {
        var myHeadings;
        var myRows = [];
        tabularData.forEach(function(d){
            myHeadings = Object.keys(d);
            var tmp = [];
            myHeadings.forEach( function(key) {
                tmp.push(d[key]);
            });
            myRows.push(tmp);
        });
        
        var table = d3.select("#dri_tabular_surrogate_display").append("table");
        var header = table.append("thead").append("tr");
        header
                .selectAll("th")
                .data(myHeadings)
                .enter()
                .append("th")
                .text(function(d) { return d; });
        var tablebody = table.append("tbody");
        var rows = tablebody
                .selectAll("tr")
                .data(myRows)
                .enter()
                .append("tr");
        var cells = rows.selectAll("td")
                .data(function(d) {
                    return d;
                })
                .enter()
                .append("td")
                .text(function(d) {
                    return d;
                });
    });

});

$(document).ready(function() {
  $('.dri_main_nav_new ul.nav li.dropdown').hover(function() {
    $(this).find('.dropdown-menu').stop(true, true).delay(100).fadeIn(200);
  }, function() {
     $(this).find('.dropdown-menu').stop(true, true).delay(100).fadeOut(200);
  });
});

$(document).ready(function() {
  // Tooltip

  $('.clipboard-btn').tooltip({
    trigger: 'click',
    placement: 'bottom'
  });

  function setTooltip(btn, message) {
    $(btn).tooltip('hide')
      .attr('data-original-title', message)
      .tooltip('show');
  }

  function hideTooltip(btn) {
    setTimeout(function() {
      $(btn).tooltip('hide');
    }, 1000);
  }

  // Clipboard
  if (clipboard) {
    clipboard.destroy();
  }
  var clipboard = new Clipboard('.clipboard-btn');

  clipboard.on('success', function(e) {
    setTooltip(e.trigger, I18n.t("dri.views.catalog.forms.copy_success"));
    hideTooltip(e.trigger);
    e.clearSelection();
  });

  clipboard.on('error', function(e) {
    setTooltip(e.trigger, I18n.t("dri.views.catalog.forms.copy_failure"));
    hideTooltip(e.trigger);
  });
});

$(function() {
  return $(".carousel").on("slid.bs.carousel", function(ev) {
    var lazy;
    lazy = $(ev.relatedTarget).find("img[data-src]");
    lazy.attr("src", lazy.data('src'));
    lazy.removeAttr("data-src");
  });
});
