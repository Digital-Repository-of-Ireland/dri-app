var map;

function generate_map(location_list) {

    var asset_location = OpenLayers._getScriptLocation();

    map = new OpenLayers.Map("map_container");
//    map.addLayer(new OpenLayers.Layer.Google("Google Streets")); //to swicth to google maps uncomment this and comment the line below
    map.addLayer(new OpenLayers.Layer.OSM()); //to swicth to open street maps uncomment this and comment the line above

    epsg4326 =  new OpenLayers.Projection("EPSG:4326"); //WGS 1984 projection
    projectTo = map.getProjectionObject(); //The map projection (Spherical Mercator)

    var lonLat = new OpenLayers.LonLat( location_list[0].location.east, location_list[0].location.north ).transform(epsg4326, projectTo);

    var zoom = 3;
    map.setCenter (lonLat, zoom);

    var marker_layer = new OpenLayers.Layer.Vector("Overlay");

    for (var i = 0; i < location_list.length; i++) {
        if (location_list[i].location.type == "box") {
            var feature = createBox(location_list[i]);
            marker_layer.addFeatures(feature);
        }
    }

    for (var i = 0; i < location_list.length; i++) {
        if (location_list[i].location.type == "point") {
            var feature = createMarker(location_list[i]);
            marker_layer.addFeatures(feature);
        }
    }

    // Define markers as "features" of the vector layer:

    map.addLayer(marker_layer);


    //Add a selector control to the marker_layer with popup functions
    var controls = {
        selector: new OpenLayers.Control.SelectFeature(marker_layer, { onSelect: createPopup, onUnselect: destroyPopup })
    };

    function createMarker(location) {
//        console.log(location.location.name);
//        console.log(location.location.north);
//        console.log(location.location.east);
//        console.log(location.object.name);
//        console.log(location.object.url);

        var description = "";
        description += location.location.name + "<br/>";
        description += "<a href=\"" + location.object.url + "\" >";
        description += location.object.name;
        description += "</a>";
        var feature = new OpenLayers.Feature.Vector(
            new OpenLayers.Geometry.Point( location.location.east, location.location.north ).transform(epsg4326, projectTo),
            {description: description} ,
            {externalGraphic: asset_location + 'img/marker.png', graphicHeight: 25, graphicWidth: 21, graphicXOffset:-12, graphicYOffset:-25  }
        );
        return feature;
    }

    function createBox(location) {
//        console.log(location.location.name);
//        console.log(location.location.northlimit);
//        console.log(location.location.southlimit);
//        console.log(location.location.eastlimit);
//        console.log(location.location.westlimit);
//        console.log(location.object.name);
//        console.log(location.object.url);

        var description = "";
        description += location.location.name + "<br/>";
        description += "<a href=\"" + location.object.url + "\" >";
        description += location.object.name;
        description += "</a>";

        var bounds_array = [location.location.eastlimit, location.location.northlimit, location.location.westlimit, location.location.southlimit];
        var bounds = OpenLayers.Bounds.fromArray(bounds_array);
        var feature = new OpenLayers.Feature.Vector(
            bounds.toGeometry().transform(epsg4326, projectTo),
            {description: description}
        );
        return feature;
    }

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

}