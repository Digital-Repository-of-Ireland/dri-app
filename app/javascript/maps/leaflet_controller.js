import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet.markercluster"

// DRI copy of blacklight-maps' leaflet controller (upstream f2819731).
// Local changes
//   1. chunked marker loading with a progress bar
//   2. larger cluster icons (xlarge for 10,000+ hits)
//   3. 'page' is dropped from the params kept by the "search this area" control
//   4. map.invalidateSize() whenever the map container is resized (map shown in a modal)

export default class extends Controller {
  static values = {
    geojson: Object,
    tileurl: { type: String, default: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' },
    mapattribution: { type: String, default: 'Map data &copy; <a href="https://openstreetmap.org">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC-BY-SA</a>' },
    initialzoom: { type: Number, default: 2 },
    maxzoom: { type: Number, default: 18 },
    singlemarkermode: { type: Boolean, default: true },
    searchcontrol: { type: Boolean, default: false },
    catalogpath: { type: String, default: 'catalog' },
    searchctrlcue: { type: String, default: 'Search for all items within the current map window' },
    placenamefield: { type: String, default: 'placename_field' },
    nodata: { type: String, default: 'Sorry, there is no data for this location.' },
    clustercount: { type: String, default: 'locations' },
    searchresultsview: { type: String, default: 'list' },
    initialview: Array,
  }

  connect() {
    var map, markers, geoJsonLayer;

    var geojson_docs = this.geojsonValue || {};

    var options = {
      tileurl: this.tileurlValue,
      mapattribution: this.mapattributionValue,
      maxzoom: this.maxzoomValue,
      initialzoom: this.initialzoomValue,
      singlemarkermode: this.singlemarkermodeValue,
      searchcontrol: this.searchcontrolValue,
      catalogpath: this.catalogpathValue,
      searchctrlcue: this.searchctrlcueValue,
      placenamefield: this.placenamefieldValue,
      nodata: this.nodataValue,
      clustercount: this.clustercountValue,
      searchresultsview: this.searchresultsviewValue,
      initialview: this.hasInitialviewValue ? this.initialviewValue : null,
    };

    var mapped_items = '<span class="mapped-count"><span class="badge bg-secondary badge-secondary">' + (geojson_docs.features ? geojson_docs.features.length : 0) + '</span>' + ' location' + ((geojson_docs.features ? geojson_docs.features.length : 0) !== 1 ? 's' : '') + ' mapped</span>';

    // progress bar shown while large marker sets load in chunks (styled in _dri.scss)
    var progress_html = '<div id="map-progress"><div id="map-progress-bar"></div></div>';

    var mapped_caveat = '<span class="mapped-caveat">Only items with location data are shown below</span>';

    var sortAndPerPage = document.querySelector('#sortAndPerPage');

    // Update page links with number of mapped items, disable sort, per_page, pagination
    if (sortAndPerPage) { // catalog#index and #map view
      var page_links = sortAndPerPage.querySelector('.page-links');
      if (page_links) {
        var result_count = page_links.querySelector('.page-entries strong:last-child') ? page_links.querySelector('.page-entries strong:last-child').innerHTML : '';
        page_links.innerHTML = '<span class="page-entries"><strong>' + result_count + '</strong> items found</span>' + mapped_items + mapped_caveat + progress_html;
      }
      sortAndPerPage.querySelectorAll('.dropdown-toggle').forEach(function(el) { el.style.display = 'none'; });
    } else { // catalog#show view
      this.element.insertAdjacentHTML('beforebegin', mapped_items + progress_html);
    }

    // determine whether to use item location or result count in cluster icon display
    var clusterIconFunction;
    if (options.clustercount == 'hits') {
      clusterIconFunction = function (cluster) {
        var clusterMarkers = cluster.getAllChildMarkers();
        var childCount = 0;
        for (var i = 0; i < clusterMarkers.length; i++) {
          childCount += clusterMarkers[i].feature.properties.hits;
        }
        // Extra 'xlarge' cluster size for 10,000+ hits
        var pointSize = 40;
        var c = ' marker-cluster-';
        if (childCount < 10) {
          c += 'small';
        } else if (childCount < 100) {
          c += 'medium';
        } else if (childCount < 10000) {
          c += 'large';
        } else {
          c += 'xlarge';
          pointSize = 60;
        }
        return new L.DivIcon({ html: '<div><span>' + childCount + '</span></div>', className: 'marker-cluster' + c, iconSize: new L.Point(pointSize, pointSize) });
      };
    }

    // Setup Leaflet map
    map = L.map(this.element, {
      center: [0, 0],
    });

    L.tileLayer(options.tileurl, {
      attribution: options.mapattribution,
      maxZoom: options.maxzoom
    }).addTo(map);

    // Update the progress bar while markers are processed in chunks.
    // Elements are looked up on each call so this is a no-op if the markup is missing.
    function updateProgressBar(processed, total, elapsed) {
      var progress = document.getElementById('map-progress');
      var progressBar = document.getElementById('map-progress-bar');
      if (!progress || !progressBar) { return; }

      if (elapsed > 1000) {
        // if it takes more than a second to load, display the progress bar
        progress.style.display = 'block';
        progressBar.style.width = Math.round(processed / total * 100) + '%';
      }

      if (processed === total) {
        // all markers processed - hide the progress bar
        progress.style.display = 'none';
      }
    }

    // Create a marker cluster object and set options
    markers = new L.MarkerClusterGroup({
      singleMarkerMode: options.singlemarkermode,
      iconCreateFunction: clusterIconFunction,
      chunkedLoading: true,
      chunkProgress: updateProgressBar
    });

    geoJsonLayer = L.geoJson(geojson_docs, {
      onEachFeature: function(feature, layer){
        if (feature.properties.popup) {
            layer.bindPopup(feature.properties.popup);
        } else {
            layer.bindPopup(options.nodata);
        }
      }
    });

    // Add GeoJSON layer to marker cluster object
    markers.addLayer(geoJsonLayer);

    // Add markers to map
    map.addLayer(markers);

    // Fit bounds of map
    setMapBounds(map);

    // create overlay for search control hover
    var searchHoverLayer = L.rectangle([[0,0], [0,0]], {
      color: "#0033ff",
      weight: 5,
      opacity: 0.5,
      fill: true,
      fillColor: "#0033ff",
      fillOpacity: 0.2
    });

    // create search control
    var searchControl = L.Control.extend({

      options: { position: 'topleft' },

      onAdd: function (map) {
        var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control');
        this.link = L.DomUtil.create('a', 'leaflet-bar-part search-control', container);
        this.link.title = options.searchctrlcue;
        this.link.href = '#';

        L.DomEvent.addListener(this.link, 'click', L.DomEvent.stop);
        L.DomEvent.addListener(this.link, 'click', _search);

        L.DomEvent.addListener(this.link, 'mouseover', function () {
          searchHoverLayer.setBounds(map.getBounds());
          map.addLayer(searchHoverLayer);
        });

        L.DomEvent.addListener(this.link, 'mouseout', function () {
          map.removeLayer(searchHoverLayer);
        });

        return container;
      }

    });

    // add search control to map
    if (options.searchcontrol === true) {
      map.addControl(new searchControl());
    }

    this._map = map;
    this._markers = markers;

    // Leaflet measures its container once, so a map created inside a hidden or
    // still-animating modal stays blank until the container is re-measured.
    if (typeof ResizeObserver !== 'undefined') {
      this._resizeObserver = new ResizeObserver(function () { map.invalidateSize(); });
      this._resizeObserver.observe(this.element);
    }

    /**
    * Sets the view of the map, based off of the map bounds
    * options.initialzoom is invoked for catalog#show views (unless it would obscure features)
    */
    function setMapBounds() {
      map.fitBounds(mapBounds(), {
        padding: [10, 10],
        maxZoom: options.maxzoom
      });
      if (document.querySelector('#document')) {
        if (map.getZoom() > options.initialzoom) {
          map.setZoom(options.initialzoom);
        }
      }
    }

    /**
    * Returns the bounds of the map based off of initialview being set or gets
    * the bounds of the markers object
    */
    function mapBounds() {
      if (options.initialview) {
        return options.initialview;
      } else {
        return markerBounds();
      }
    }

    /**
    * Returns the bounds of markers, if there are not any return
    */
    function markerBounds() {
      if (hasAnyFeatures()) {
        return markers.getBounds();
      } else {
        return [[90, 180], [-90, -180]];
      }
    }

    /**
    * Checks to see if there are any features in the markers MarkerClusterGroup
    */
    function hasAnyFeatures() {
      var has_features = false;
      markers.eachLayer(function (layer) {
        if (layer) {
          has_features = true;
        }
      });
      return has_features;
    }

    // remove stale params, add new params, and run a new search
    function _search() {
      var params = filterParams(['page', 'view', 'spatial_search_type', 'coordinates', 'f%5B' + options.placenamefield + '%5D%5B%5D']),
          bounds = map.getBounds().toBBoxString().split(',').map(function(coord) {
            if (parseFloat(coord) > 180) {
              coord = '180';
            } else if (parseFloat(coord) < -180) {
              coord = '-180';
            }
            return Math.round(parseFloat(coord) * 1000000) / 1000000;
          }),
          coordinate_params = '[' + bounds[1] + ',' + bounds[0] + ' TO ' + bounds[3] + ',' + bounds[2] + ']';
      params.push('coordinates=' + encodeURIComponent(coordinate_params), 'spatial_search_type=bbox', 'view=' + options.searchresultsview);
      window.location.href = options.catalogpath + '?' + params.join('&');
    }

    // remove unwanted params
    function filterParams(filterList) {
      var querystring = window.location.search.substr(1),
          params = [];
      if (querystring !== "") {
        params = querystring.split('&').filter(function(value) {
          return filterList.indexOf(value.split('=')[0]) === -1;
        });
      }
      return params;
    }
  }

  disconnect() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect();
      this._resizeObserver = null;
    }
    if (this._map) {
      this._map.remove();
      this._map = null;
      this._markers = null;
    }
  }
}
