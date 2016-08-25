module DRI::IIIFViewable

  require 'iiif/presentation'

  HEIGHT_SOLR_FIELD = 'height_isi'
  WIDTH_SOLR_FIELD = 'width_isi'

  def iiif_manifest
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
      canvas['@id'] = "#{seed_id}/canvas/#{f.id}"
      # ...but there are also accessors and mutators for the properties mentioned in 
      # the spec
      canvas.width = f[HEIGHT_SOLR_FIELD]
      canvas.height = f[WIDTH_SOLR_FIELD]
      canvas.label = f[ActiveFedora.index_field_mapper.solr_name('label')]

      image_url = Riiif::Engine.routes.url_for controller: 'riiif/images', action: 'show', 
          id: f.id, region: 'full', size: 'full', rotation: 0, quality: 'default', format: 'jpg', only_path: true

      image = IIIF::Presentation::ImageResource.new({'@id' => "#{root_url}#{image_url}"})
      image.width = f[WIDTH_SOLR_FIELD]
      image.height = f[HEIGHT_SOLR_FIELD]

      image.service = IIIF::Service.new({'@id' => "#{root_url}/images/#{f.id}"})

      canvas.images << image

      manifest.sequences << canvas
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