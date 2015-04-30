// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require video
//= require jquery
//= require jquery_ujs
//
// Required by Blacklight-Maps
//= require blacklight-maps
//= require jquery.remotipart
//= require jquery.cookie
//= require bootstrap/carousel
//= require bootstrap/tooltip
//= require bootstrap/popover
//= require bootstrap/tab
//= require bootstrap-switch
//= require timelineJS/embed
//= require timelineJS/locale/en
//= require openlayers-rails
// Required by Blacklight
//= require blacklight/blacklight
//= Required by Dropit dropdown menu library
//= require dropit/dropit
//
//= require dri/
//= require colorbox-rails
//= require bootstrap-datepicker
//= require social-share-button

$(document).ready(function() {
    $('dropdown').dropdown();
    $('#dri_cookie_modal').modal({keyboard: false, backdrop: 'static'});
    $('.carousel').carousel();
    $('.dri_help_popover_slow, #facets, #dri_social_media_links_id, #dri_sort_options_id, #dri_change_sort_view_id, #dri_page_options_id, #dri_facet_restrictions_links_id, #dri_pagination_nav_links_id, #dri_browse_sort_tabs_collections_id, #dri_browse_sort_tabs_objects_id').popover( {delay: { show: 1500, hide: 100 }} );
    $('.dri_help_popover').popover( {delay: { show: 100, hide: 100 }} );
    $('.dri_help_tooltip').tooltip( {delay: { show: 100, hide: 100 }} );
    $('a.dri_gallery').colorbox({rel:'group1'});
});

$(function(){
    // bind change event to select
    $('#dri_sort_options_id').bind('change', function () {
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
  



// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

