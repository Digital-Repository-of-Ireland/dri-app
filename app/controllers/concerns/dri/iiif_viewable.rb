module DRI::IIIFViewable

  require 'iiif/presentation'

  HEIGHT_SOLR_FIELD = 'height_isi'
  WIDTH_SOLR_FIELD = 'width_isi'

  # patch issue with as_json wrapping keys in data and changing key order
  # may be resolved by iiif-prezi/osullivan/issues/72
  [
    IIIF::Presentation::Collection,
    IIIF::Presentation::Manifest,
  ].each do |iiif_class|
    iiif_class.class_eval do
      define_method(:as_json) do
        JSON.parse(self.to_json)
      end
    end
  end

  def iiif_manifest
    object_url = ''

    if @document.collection?
      create_collection_manifest
    else
      create_object_manifest
    end
  end

  def iiif_sequence
    if @document.collection?
      create_collection_sequence
    else
      # TODO, get parent collection id
      # use create_collection_sequence to generate manifest, but target image from current object
      # so that full collection is opened in mirador, but with the current object selected
      create_object_manifest
    end
  end

  def iiif_base_url(solr_id = nil)
    solr_id ||= @document.id
    url_for(controller: 'iiif', action: 'show', id: solr_id)
  end

  def create_object_manifest
    seed_id = url_for controller: 'iiif', action: 'manifest', id: @document.id, format: 'json'

    seed = {
      '@id' => seed_id,
      'label' => @document.title.join(','),
      'description' => @document.description.join(' ')
    }

    manifest = IIIF::Presentation::Manifest.new(seed)
    base_manifest(manifest)

    if @document.collection_id
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

  def create_collection_sequence
    manifest = IIIF::Presentation::Manifest.new(collection_manifest_seed)
    base_manifest(manifest)

    sequence = IIIF::Presentation::Sequence.new(
      '@id' => "#{iiif_base_url}/sequence/normal",
      'viewing_hint' => 'individuals'
    )

    # TODO: check why child_objects is empty in dev env
    # issue with object_type in solr?
    # Add collapsible subcollections to structures like
    # https://iiif.lib.harvard.edu/manifests/drs:48309543
    # objects = child_objects

    # assumes images always have a title
    objects = @document.published_images.sort_by(&:title)

    # exit early if @document doesn't have published images
    return manifest if objects.empty?

    objects.each_with_index do |image_object, obj_idx|
      # TODO: simplify this block
      # will we ever want to display  more than one image per object?
      attached_images(image_object.id).each_with_index do |image_file, file_idx|
        canvas = create_canvas(image_file, iiif_base_url(image_object.id), image_object.id)
        canvas.see_also = see_also(image_object.id)
        sequence.canvases << canvas
        manifest.structures << {
          # canvas id is entire url, not just object.id
          'canvases' => [canvas["@id"]],
          '@id' => "#{iiif_base_url}/range/range-#{obj_idx + 1}-#{file_idx + 1}.json",
          '@type' => "sc:Range",
          'label' => "#{obj_idx + 1}. #{image_object.title.first.truncate(100)}"
        }
      end
    end

    manifest.sequences << sequence
    manifest
  end

  def create_collection_manifest
    manifest = IIIF::Presentation::Collection.new(collection_manifest_seed)
    base_manifest(manifest)

    if @document.collection_id.nil?
      manifest.viewing_hint = 'top'
    else
      manifest.within = create_within
    end

    sub_collections = @document.children
    unless sub_collections.empty?
      sub_collections.each { |c| manifest.collections << create_subcollection(c) }
    end

    sequence = IIIF::Presentation::Sequence.new(
        {'@id' => "#{iiif_base_url}/sequence/normal",
        'viewing_hint' => 'individuals'})

    objects = child_objects

    unless objects.empty?
      objects.each do |o|
        manifest.manifests << create_manifest(o)
      end
    end

    manifest
  end

  def collection_manifest_seed
    seed_id = iiif_collection_manifest_url id: @document.id, format: 'json'

    seed = {
      '@id' => seed_id,
      'label' => @document.title.join(','),
      'description' => @document.description.join(' ')
    }
  end

  def attached_images(solr_id = nil)
    solr_id ||= @document.id

    files_query = "isPartOf_ssim:#{solr_id}"

    fq = [
           "active_fedora_model_ssi:\"DRI::GenericFile\"",
           "file_type_sim:\"image\"",
           "-preservation_only_ssi:true",
           "#{WIDTH_SOLR_FIELD}:[* TO *]",
           "#{HEIGHT_SOLR_FIELD}:[* TO *]"
         ]
    files = []

    query = Solr::Query.new(files_query, 1000, {fq: fq})
    files = query.to_a

    files.sort_by{ |f| f['label_tesim'] }
  end

  def base_manifest(manifest)
    solr_doc = @document

    manifest.metadata = create_metadata
    manifest.see_also = see_also

    attributions = []
    depositing_org, logo = depositing_org_info(solr_doc)
    attributions << depositing_org.name if depositing_org
    manifest.logo = logo if logo

    attributions.push(*@document.rights)

    licence = solr_doc.licence
    if licence && licence.url
      manifest.license = licence.url
    end

    manifest.attribution = attributions.join(', ')
  end

  def child_objects
    # query for objects within this collection
    q_str = "#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{@document.id}\""
    q_str += " AND status_ssi:\"published\""
    q_str += " AND #{Solrizer.solr_name('file_count', :stored_sortable, type: :integer)}:[1 TO *]"
    q_str += " AND #{Solrizer.solr_name('file_type', :facetable)}:\"image\""
    # excluding sub-collections
    f_query = "is_collection_ssi:false"

    objects = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    query.to_a
  end

  def create_canvas(file, iiif_base_url, solr_id = nil)
    solr_id ||= @document.id
    canvas = IIIF::Presentation::Canvas.new()
    canvas['@id'] = "#{iiif_base_url}/canvas/#{file.id}"
    canvas.width = file[WIDTH_SOLR_FIELD]
    canvas.height = file[HEIGHT_SOLR_FIELD]
    canvas.label = file['label_tesim'].first

    base_uri = Settings.iiif.server + '/' + solr_id + ':' + file.id
    image_url =  base_uri + '/full/full/0/default.jpg'

    image = IIIF::Presentation::ImageResource.create_image_api_image_resource(
    {
      resource_id: image_url,
      service_id: base_uri,
      width: file[WIDTH_SOLR_FIELD], height: file[HEIGHT_SOLR_FIELD],
      profile: 'https://iiif.io/api/image/2/level2.json'
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
        'label' => object[Solrizer.solr_name('title')].join(', ')
    }
  end

  def create_metadata
    metadata = []
    metadata << { 'label' => 'Creator', 'value' => @document.creator.join(', ') } unless @document.creator.blank?
    metadata << { 'label' => 'Title', 'value' => @document.title.join(', ') } unless @document.title.blank?
    metadata << { 'label' => 'Creation date', 'value' => @document.creation_date.first } unless @document.creation_date.blank?
    metadata << { 'label' => 'Published date', 'value' => @document.published_date.first } unless @document.published_date.blank?
    metadata << { 'label' => 'Date', 'value' => @document.date.first } unless @document.date.blank?
    metadata << { 'label' => 'Permalink', 'value' => "doi:10.7486/DRI.#{@document.id}" }

    metadata
  end

  def create_subcollection(collection)
    {
        '@id' => iiif_collection_manifest_url(id: collection.id, format: 'json'),
        '@type' => 'sc:Collection',
        'label' => collection[Solrizer.solr_name('title')].join(', ')
    }
  end

  def create_within
    governing_collection = @document.governing_collection

    {
        '@id' => (iiif_collection_manifest_url id: governing_collection.id, format: 'json'),
        '@type' => 'sc:Collection',
        'label' => governing_collection.title.join(', ')
    }
  end

  def depositing_org_info(solr_doc)
    org = solr_doc.depositing_institute

    depositing_org = nil
    logo = nil

    if org
      depositing_org = org
      logo = logo_url(id: org.id)
    end

    return depositing_org, logo
  end

  def see_also(solr_id = nil)
    solr_id ||= @document.id
    {
      "@id" => object_metadata_url(id: solr_id),
      'format' => 'text/xml'
    }
  end
end
