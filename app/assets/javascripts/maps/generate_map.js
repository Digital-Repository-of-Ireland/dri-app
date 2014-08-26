var map;

function generate_map(location_list) {

    var asset_location = OpenLayers._getScriptLocation();

    map = new OpenLayers.Map("map_container");
    map.addLayer(new OpenLayers.Layer.OSM());

    epsg4326 =  new OpenLayers.Projection("EPSG:4326"); //WGS 1984 projection
    projectTo = map.getProjectionObject(); //The map projection (Spherical Mercator)

    var lonLat = new OpenLayers.LonLat( location_list[0].location.east, location_list[0].location.north ).transform(epsg4326, projectTo);

    var zoom=3;
    map.setCenter (lonLat, zoom);

    var vectorLayer = new OpenLayers.Layer.Vector("Overlay");

    for (var i = 0; i < location_list.length; i++) {

        console.log(location_list[i].location.name);
        console.log(location_list[i].location.north);
        console.log(location_list[i].location.east);
        console.log(location_list[i].object.name);
        console.log(location_list[i].object.url);

        var description = "";
        description += location_list[i].location.name + "<br/>";
        description += "<a href=\"" + location_list[i].object.url + "\" >";
        description += location_list[i].object.name;
        description += "</a>";
        var feature = new OpenLayers.Feature.Vector(
            new OpenLayers.Geometry.Point( location_list[i].location.east, location_list[i].location.north ).transform(epsg4326, projectTo),
            {description: description} ,
            {externalGraphic: asset_location + 'img/marker.png', graphicHeight: 25, graphicWidth: 21, graphicXOffset:-12, graphicYOffset:-25  }
        );
        vectorLayer.addFeatures(feature);
    }

    // Define markers as "features" of the vector layer:



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

}