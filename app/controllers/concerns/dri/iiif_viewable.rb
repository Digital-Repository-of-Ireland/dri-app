module DRI::IIIFViewable

  require 'iiif/presentation'

  HEIGHT_SOLR_FIELD = 'height_isi'
  WIDTH_SOLR_FIELD = 'width_isi'

  def iiif_manifest
    object_url = url_for controller: 'objects', action: 'show', id: @object.id
    seed_id = url_for controller: 'objects', action: 'manifest', id: @object.id, format: 'json'

    seed = {
      '@id' => seed_id,
      'label' => @object.title.join(','),
      'description' => @object.description.join(' ')
    }
    
    manifest = IIIF::Presentation::Manifest.new(seed)
    solr_doc = SolrDocument.new(@object.to_solr)

    manifest.metadata = create_metadata

    org = InstituteHelpers.get_depositing_institute_from_solr_doc(solr_doc)

    attributions = []
    if org
      attributions << org.name
      manifest.logo = "#{root_url}/organisations/#{org.id}/logo"
    end

    attributions.push(*@object.rights)

    licence = solr_doc.licence
    if licence && licence.url
      manifest.license = licence.url 
    end

    manifest.attribution = attributions.join(', ')

    sequence = IIIF::Presentation::Sequence.new(
        {'@id' => "#{object_url}/sequence/normal", 
        'viewing_hint' => 'individuals'})

    files = attached_images
    files.each { |f| sequence.canvases << create_canvas(f) }  
    
    manifest.sequences << sequence
    manifest
  end

  def attached_images
    files_query = "active_fedora_model_ssi:\"DRI::GenericFile\""
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name('isPartOf', :symbol)}:#{@object.id}"
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)}:\"image\""
    files_query += " AND NOT #{ActiveFedora.index_field_mapper.solr_name('dri_properties__preservation_only', :stored_searchable)}:true"

    files = []
    
    query = Solr::Query.new(files_query)
    query.each_solr_document { |file_doc| files << file_doc }

    files.sort_by{ |f| f[ActiveFedora.index_field_mapper.solr_name('label')] }
  end

  def create_canvas(file)
    canvas = IIIF::Presentation::Canvas.new()
    canvas['@id'] = "#{object_url}/canvas/#{file.id}"
    
    canvas.width = file[HEIGHT_SOLR_FIELD]
    canvas.height = file[WIDTH_SOLR_FIELD]
    canvas.label = file[ActiveFedora.index_field_mapper.solr_name('label')]

    image_url = Riiif::Engine.routes.url_for controller: 'riiif/images', action: 'show', 
        id: file.id, region: 'full', size: 'full', rotation: 0, 
        quality: 'default', format: 'jpg', only_path: true   

    image = IIIF::Presentation::ImageResource.create_image_api_image_resource(
    {
      resource_id: "#{root_url}#{image_url}",
      service_id: "#{root_url}/images/#{file.id}",
      width: file[WIDTH_SOLR_FIELD], height: file[HEIGHT_SOLR_FIELD],
      profile: 'http://iiif.io/api/image/2/profiles/level2.json'
    })
    image['@type'] = 'dctypes:Image'

    annotation = IIIF::Presentation::Annotation.new
    annotation['on'] = canvas['@id']
    annotation.resource = image

    canvas.images << annotation

    canvas
  end

  def create_metadata
    metadata = [
      { 'label' => 'Creator', 'value' => @object.creator.join(', ') },
      { 'label' => 'Title', 'value' => @object.title.join(', ') }
    ]

    metadata << { 'label' => 'Creation date', 'value' => @object.creation_date.first } if @object.creation_date.first.present?
    metadata << { 'label' => 'Published date', 'value' => @object.published_date.first } if @object.published_date.first.present?
    metadata << { 'label' => 'Date', 'value' => @object.date.first } if @object.date.first.present?
    metadata << { 'label' => 'Permalink', 'value' => "doi:#{@object.doi}" } if @object.doi

    metadata
  end

end