module DRI
  class ObjectPresenter

    attr_reader :document
    delegate :solr_document_path, :params, :link_to, :image_tag, :logo_path, :uri?, to: :@view

    FILE_TYPE_LABELS = {
      'image' => 'Image',
      'audio' => 'Sound',
      'video' => 'MovingImage',
      'text' => 'Text',
      '3d' => '3D',
      'mixed_types' => 'MixedType'
    }

    def initialize(document, view_context)
      @view = view_context
      @document = document
    end

    def display_children(children)
      children.map { |child| display_child(child) }
    end

    def external_relationships
      Kaminari.paginate_array(document.external_relationships).page(params[:externs_page]).per(4)
    end

    def organisations
      @organisations ||= document.institutes
    end

    def depositing_organisation
      @depositing_organisation ||= document.depositing_institute
    end

    def display_organisation(organisation)
      return display_brand(organisation) if organisation.brand

      organisation.url.present? ? link_to(organisation.name, organisation.url, target: "_blank") : organisation.name
    end

    def file_type_labels
      types = document.file_types

      return I18n.t('dri.data.types.Unknown') if types.blank?

      labels = []
      types.each do |type|
        label = FILE_TYPE_LABELS[type.to_s.downcase] || 'Unknown'
        labels << label
      end

      labels = labels.uniq
      label = labels.length > 1 ? FILE_TYPE_LABELS['mixed_types'] : labels.first

      I18n.t("dri.data.types.#{label}")
    end

    def subjects
      subject_key = ActiveFedora.index_field_mapper.solr_name('subject', :stored_searchable, type: :string).to_sym
      return nil unless document.key?(subject_key)

      document[subject_key].reject { |s| uri?(s) }[0..2].join(" | ")
    end

    def surrogate_url(file_id, name)
      return nil unless surrogate_exists?(file_id, name)

      object_file_url(
        object_id: document.id,
        id: file_id,
        surrogate: name,
      )
    end

    def surrogate_exists?(id, name)
      document.surrogates(id).key?(name)
    end

    private

    Child = Struct.new(:id, :link_text, :path, :type, :cover) do
      def to_partial_path
        'child'
      end
    end

    # logo_path links to the InstituteController which looks up the Brand for the Institute to retrieve the logo image
    def display_brand(organisation)
      if organisation.url.present?
        link_to image_tag(logo_path(organisation), height: "75px", alt: organisation.name), organisation.url, target: "_blank"
      else
        image_tag logo_path(organisation), height: "75px", alt: organisation.name
      end
    end

    def display_child(child_doc)
      link_text = child_doc[ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)].first
      # FIXME: For now, the EAD type is indexed last in the type solr index, review in the future
      type = child_doc[ActiveFedora.index_field_mapper.solr_name('type', :stored_searchable, type: :string)].last
      cover = child_doc[ActiveFedora.index_field_mapper.solr_name('cover_image', :stored_searchable, type: :string).to_sym].presence

      child = Child.new
      child.id = child_doc['id']
      child.link_text = link_text
      child.path = solr_document_path(child_doc['id'])
      child.cover = cover
      child.type = type

      child
    end
  end
end
