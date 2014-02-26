module Utils

  def numeric?(number)
    Integer(number) rescue false
  end


  def dcterms_point_to_geojson(point)
    point_hash = {}

    point.split(/;\s*/).each do |component|
      (key,value) = component.split(/=/)
      point_hash[key] = value
    end

    tmp_hash = {}
    geojson_hash = {}

    coords = [Float(point_hash['east']), Float(point_hash['north'])]
    tmp_hash[:name] = point_hash['name']

    geojson_hash[:type] = 'Point'
    geojson_hash[:coordinates] = coords
    geojson_hash[:properties] = tmp_hash

    return geojson_hash
  end

end
