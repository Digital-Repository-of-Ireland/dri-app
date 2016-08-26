module DRI::IIIFViewable

  require 'iiif/presentation'

  HEIGHT_SOLR_FIELD = 'height_isi'
  WIDTH_SOLR_FIELD = 'width_isi'

  def iiif_manifest
    object_url = url_for controller: 'objects', action: 'show', id: @object.id
    seed_id = url_for controller: 'objects', action: 'manifest', id: @object.id, format: 'json'

    seed = {
      '@id' => seed_id,
      'label' => @object.title.first,
      'description' => @object.description.first
    }
    # Any options you add are added to the object
    manifest = IIIF::Presentation::Manifest.new(seed)

    files = attached_images
    files.each do |f| 
      canvas = IIIF::Presentation::Canvas.new()
      canvas['@id'] = "#{object_url}/canvas/#{f.id}"
      # ...but there are also accessors and mutators for the properties mentioned in 
      # the spec
      canvas.width = f[HEIGHT_SOLR_FIELD]
      canvas.height = f[WIDTH_SOLR_FIELD]
      canvas.label = f[ActiveFedora.index_field_mapper.solr_name('label')]

      image_url = Riiif::Engine.routes.url_for controller: 'riiif/images', action: 'show', 
          id: f.id, region: 'full', size: 'full', rotation: 0, quality: 'default', format: 'jpg', only_path: true   

      image = IIIF::Presentation::ImageResource.create_image_api_image_resource({resource_id: "#{root_url}#{image_url}",
        service_id: "#{root_url}/images/#{f.id}",
        width: f[WIDTH_SOLR_FIELD], height: f[HEIGHT_SOLR_FIELD],
        profile: 'http://iiif.io/api/image/2/profiles/level2.json'})
      image['@type'] = 'dctypes:Image'

      annotation = IIIF::Presentation::Annotation.new
      annotation['on'] = canvas['@id']
      annotation.resource = image

      canvas.images << annotation
      sequence = IIIF::Presentation::Sequence.new({'@id' => "#{object_url}/sequence/normal", 'viewing_hint' => 'individuals'})
      sequence.canvases << canvas   

      manifest.sequences << sequence
    end

    manifest
  end

  def attached_images
    files_query = "active_fedora_model_ssi:\"DRI::GenericFile\""
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name("isPartOf", :symbol)}:#{@object.id}"
    files_query += " AND #{ActiveFedora.index_field_mapper.solr_name("file_type", :stored_searchable, type: :string)}:\"image\""
    files_query += " AND NOT #{ActiveFedora::SolrQueryBuilder.solr_name('dri_properties__preservation_only', :stored_searchable)}:true"

    files = []
    
    query = Solr::Query.new(files_query)
    query.each_solr_document { |file_doc| files << file_doc }

    files
  end

end