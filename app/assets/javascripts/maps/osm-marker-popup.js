var map;
function init() {

    var asset_location = OpenLayers._getScriptLocation();

    map = new OpenLayers.Map("map_container");
    map.addLayer(new OpenLayers.Layer.OSM());

    epsg4326 =  new OpenLayers.Projection("EPSG:4326"); //WGS 1984 projection
    projectTo = map.getProjectionObject(); //The map projection (Spherical Mercator)

    var lonLat = new OpenLayers.LonLat( -0.1279688 ,51.5077286 ).transform(epsg4326, projectTo);


    var zoom=14;
    map.setCenter (lonLat, zoom);

    var vectorLayer = new OpenLayers.Layer.Vector("Overlay");

    // Define markers as "features" of the vector layer:
    var feature = new OpenLayers.Feature.Vector(
        new OpenLayers.Geometry.Point( -0.1279688, 51.5077286 ).transform(epsg4326, projectTo),
        {description:'This is the value of<br>the description attribute'} ,
        {externalGraphic: asset_location + 'img/marker.png', graphicHeight: 25, graphicWidth: 21, graphicXOffset:-12, graphicYOffset:-25  }
    );
    vectorLayer.addFeatures(feature);

    var feature = new OpenLayers.Feature.Vector(
        new OpenLayers.Geometry.Point( -0.1244324, 51.5006728  ).transform(epsg4326, projectTo),
        {description:'Big Ben'} ,
        {externalGraphic: asset_location + 'img/marker.png', graphicHeight: 25, graphicWidth: 21, graphicXOffset:-12, graphicYOffset:-25  }
    );
    vectorLayer.addFeatures(feature);

    var feature = new OpenLayers.Feature.Vector(
        new OpenLayers.Geometry.Point( -0.119623, 51.503308  ).transform(epsg4326, projectTo),
        {description:'London Eye'} ,
        {externalGraphic: asset_location + 'img/marker.png', graphicHeight: 25, graphicWidth: 21, graphicXOffset:-12, graphicYOffset:-25  }
    );
    vectorLayer.addFeatures(feature);


    map.addLayer(vectorLayer);


    //Add a selector control to the vectorLayer with popup functions
    var controls = {
        selector: new OpenLayers.Control.SelectFeature(vectorLayer, { onSelect: createPopup, onUnselect: destroyPopup })
    };

    function createPopup(feature) {
        feature.popup = new OpenLayers.Popup.FramedCloud("pop",
            feature.geometry.getBounds().getCenterLonLat(),
            null,
                '<div class="markerContent">'+feature.attributes.description+'</div>',
            null,
            true,
            function() { controls['selector'].unselectAll(); }
        );
        //feature.popup.closeOnMove = true;
        map.addPopup(feature.popup);
    }

    function destroyPopup(feature) {
        feature.popup.destroy();
        feature.popup = null;
    }

    map.addControl(controls['selector']);
    controls['selector'].activate();

//    // The marker layer for our marker, with a simple diamond as symbol
//    var marker = new OpenLayers.Layer.Vector('marker', {
//        styleMap: new OpenLayers.StyleMap({
//            externalGraphic: asset_location + '/img/marker.png',
//            graphicWidth: 20, graphicHeight: 24, graphicYOffset: -24,
//            title: '${tooltip}'
//        })
//    });
//
//    // The location of our marker and popup. We usually think in geographic
//    // coordinates ('EPSG:4326'), but the map is projected ('EPSG:3857').
//    var myLocation = new OpenLayers.Geometry.Point(10.2, 48.9)
//        .transform('EPSG:4326', 'EPSG:3857');
//
//    // We add the marker with a tooltip text to the marker
//    marker.addFeatures([
//        new OpenLayers.Feature.Vector(myLocation, {tooltip: 'OpenLayers'})
//    ]);
//
//    // A popup with some information about our location
//    var popup = new OpenLayers.Popup.FramedCloud("Popup",
//        myLocation.getBounds().getCenterLonLat(), null,
//            '<a target="_blank" href="http://openlayers.org/">We</a> ' +
//            'could be here.<br>Or elsewhere.', null,
//        true // <-- true if we want a close (X) button, false otherwise
//    );
//
//    // Finally we create the map
//    map = new OpenLayers.Map({
//        div: "map_container", projection: "EPSG:3857",
//        layers: [new OpenLayers.Layer.OSM(), marker],
//        center: myLocation.getBounds().getCenterLonLat(),
//        zoom: 1
//    });
//    // and add the popup to it.
//    map.addPopup(popup);
}