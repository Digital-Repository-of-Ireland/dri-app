module Utils

  def numeric?(number)
    Integer(number) rescue false
  end

  def self.split_id(pid)
    pid.sub("#{Rails.application.config.id_namespace}:", '')
  end

  def dcterms_point_to_geojson(point)
    return nil if point.blank?
    point_hash = {}

    point.split(/\s*;\s*/).each do |component|
      (key,value) = component.split(/\s*=\s*/)
      point_hash[key] = value
    end

    return nil unless point_hash.keys.include?('name')

    tmp_hash = {}
    geojson_hash = {}
    geojson_hash[:type] = 'Feature'
    geojson_hash[:geometry] = {}

    coords = [Float(point_hash['east']), Float(point_hash['north'])]
    tmp_hash[:name] = point_hash['name']

    geojson_hash[:geometry][:type] = 'Point'
    geojson_hash[:geometry][:coordinates] = coords
    geojson_hash[:properties] = tmp_hash

    return geojson_hash
  end


  def dcterms_box_to_geojson(box)
    return nil if box.blank?
    point_hash = {}

    box.split(/\s*;\s*/).each do |component|
      (key,value) = component.split(/\s*=\s*/)
      point_hash[key] = value
    end

    return nil unless point_hash.keys.include?('name')

    tmp_hash = {}
    geojson_hash = {}
    geojson_hash[:type] = 'Feature'
    geojson_hash[:geometry] = {}

    coords = [[
      [Float(point_hash['westlimit']), Float(point_hash['northlimit'])],
      [Float(point_hash['westlimit']), Float(point_hash['southlimit'])],
      [Float(point_hash['eastlimit']), Float(point_hash['southlimit'])],
      [Float(point_hash['eastlimit']), Float(point_hash['northlimit'])]
    ]]
    tmp_hash[:name] = point_hash['name']

    geojson_hash[:geometry][:type] = 'Polygon'
    geojson_hash[:geometry][:coordinates] = coords
    geojson_hash[:properties] = tmp_hash

    return geojson_hash
  end

  def dcterms_period_to_string(period)
    return nil if period.nil? || period.blank?

    period.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if k.eql?('name')
        return v unless v.nil? || v.empty?
      end
    end
    return period

  end
end
