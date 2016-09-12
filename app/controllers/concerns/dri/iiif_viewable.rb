module DRI::IIIFViewable

  require 'iiif/presentation'

  HEIGHT_SOLR_FIELD = 'height_isi'
  WIDTH_SOLR_FIELD = 'width_isi'

  def iiif_manifest
    object_url = ''

    if @object.collection?
      create_collection_manifest
    else
      create_object_manifest
    end
  end

  def iiif_base_url
    iiif_base_url = url_for controller: 'iiif', action: 'show', id: @object.id,
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
  end

  def create_object_manifest
    seed_id = url_for controller: 'iiif', action: 'manifest', id: @object.id, format: 'json',
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol]

    seed = {
      '@id' => seed_id,
      'label' => @object.title.join(','),
      'description' => @object.description.join(' ')
    }
    
    manifest = IIIF::Presentation::Manifest.new(seed)
    base_manifest(manifest)
    
    if @object.governing_collection
      manifest.within = create_within
    end

    sequence = IIIF::Presentation::Sequence.new(
        {'@id' => "#{iiif_base_url}/sequence/normal", 
        'viewing_hint' => 'individuals'})

    files = attached_images
    files.each { |f| sequence.canvases << create_canvas(f, iiif_base_url) }  
    
    manifest.sequences << sequence
    manifest
  end

  def create_collection_manifest
    seed_id = iiif_collection_manifest_url id: @object.id, format: 'json',
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol]

    seed = {
      '@id' => seed_id,
      'label' => @object.title.join(','),
      'description' => @object.description.join(' ')
    }

    manifest = IIIF::Presentation::Collection.new(seed)
    base_manifest(manifest)

    if @object.governing_collection.nil?
      manifest.viewing_hint = 'top'
    else
      manifest.within = create_within
    end

    sub_collections = child_collections
    unless sub_collections.empty?
      sub_collections.each { |c| manifest.collections << create_subcollection(c) }
    end

    objects = child_objects
    unless objects.empty?
      objects.each { |o| manifest.manifests << create_manifest(o) }
    end

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

  def base_manifest(manifest)
    solr_doc = SolrDocument.new(@object.to_solr)

    manifest.metadata = create_metadata

    attributions = []
    depositing_org, logo = depositing_org_info(solr_doc)
    attributions << depositing_org.name if depositing_org
    manifest.logo = logo if logo

    attributions.push(*@object.rights)

    licence = solr_doc.licence
    if licence && licence.url
      manifest.license = licence.url 
    end

    manifest.attribution = attributions.join(', ')
  end

  def child_collections
    # query for objects within this collection
    q_str = "#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable, type: :string)}:\"#{@object.id}\""
    # that are also collections
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    sub_collections = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    query.each_solr_document { |collection_doc| sub_collections << collection_doc }

    sub_collections
  end

  def child_objects
    # query for objects within this collection
    q_str = "#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable, type: :string)}:\"#{@object.id}\""
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('file_count', :stored_sortable, type: :integer)}:[1 TO *]"
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('object_type', :facetable, type: :string)}:\"Image\""
    # excluding sub-collections
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    objects = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    query.each_solr_document { |object_doc| objects << object_doc }

    objects
  end

  def create_canvas(file, iiif_base_url)
    canvas = IIIF::Presentation::Canvas.new()
    canvas['@id'] = "#{iiif_base_url}/canvas/#{file.id}"
    
    canvas.width = file[HEIGHT_SOLR_FIELD]
    canvas.height = file[WIDTH_SOLR_FIELD]
    canvas.label = file[ActiveFedora.index_field_mapper.solr_name('label')].first

    image_url = Riiif::Engine.routes.url_for controller: 'riiif/images', action: 'show', 
        id: file.id, region: 'full', size: 'full', rotation: 0, 
        quality: 'default', format: 'jpg', only_path: false,
        host: Rails.application.routes.default_url_options[:host],
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
 
    image_base = image_url.split(file.id).first

    image = IIIF::Presentation::ImageResource.create_image_api_image_resource(
    {
      resource_id: "#{image_url}",
      service_id: "#{image_base}/#{file.id}",
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

  def create_manifest(object)
    { 
        '@id' => url_for(controller: 'iiif', action: 'manifest', id: object.id, format: 'json',
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]),
        '@type' => 'sc:Manifest',
        'label' => object[ActiveFedora.index_field_mapper.solr_name('title')].join(', ')
    }
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

  def create_subcollection(collection)
    { 
        '@id' => iiif_collection_manifest_url(id: collection.id, format: 'json',
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol]),
        '@type' => 'sc:Collection',
        'label' => collection[ActiveFedora.index_field_mapper.solr_name('title')].join(', ')
    }
  end

  def create_within
    governing_collection = @object.governing_collection

    { 
        '@id' => (iiif_collection_manifest_url id: governing_collection.id, format: 'json',
      protocol: Rails.application.config.action_mailer.default_url_options[:protocol]),
        '@type' => 'sc:Collection',
        'label' => governing_collection.title.join(', ')
    }
  end

  def depositing_org_info(solr_doc)
    org = InstituteHelpers.get_depositing_institute_from_solr_doc(solr_doc)

    depositing_org = nil
    logo = nil

    if org
      depositing_org = org
      logo = logo_url(id: org.id, 
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol])
    end

    return depositing_org, logo
  end

end