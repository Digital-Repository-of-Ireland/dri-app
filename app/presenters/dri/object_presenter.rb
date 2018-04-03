module DRI
  class ObjectPresenter

    attr_reader :document
    delegate :catalog_path, :params, :link_to, :image_tag, :logo_path, to: :@view

    def initialize(document, view_context)
      @view = view_context
      @document = document
    end
    
    def display_children
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
      if organisation.brand.nil? && organisation.url.blank?
        organisaton.name
      elsif organisation.brand.nil? && organisation.url.blank?
        link_to(organisation.name, organisation.url, target: "_blank")
      elsif organisation.brand && organisation.url.blank?
        image_tag logo_path(organisation), height: "75px", alt: organisation.brand.filename
      else
        link_to image_tag(logo_path(organisation), height: "75px", alt: organisation.brand.filename), organisation.url, target: "_blank"
      end
    end

    private

    Child = Struct.new(:id, :link_text, :path, :type, :cover) do
      def to_partial_path
        'child'
      end
    end

    def display_child(child_doc)
      link_text = child_doc[Solrizer.solr_name('title', :stored_searchable, type: :string)].first
      # FIXME: For now, the EAD type is indexed last in the type solr index, review in the future
      type = child_doc[Solrizer.solr_name('type', :stored_searchable, type: :string)].last
      cover = child_doc[Solrizer.solr_name('cover_image', :stored_searchable, type: :string).to_sym].presence

      child = Child.new
      child.id = child_doc['id']
      child.link_text = link_text
      child.path = catalog_path(child_doc['id'])
      child.cover = cover
      child.type = type

      child
    end
  end
end
