module DRI
  class CatalogPresenter < ObjectPresenter

    def children
      @children ||= document.children(100).select { |child| child.published? }
    end

    def displayfiles
      @displayfiles ||= @document.assets(false).sort_by! { |f| f[ActiveFedora.index_field_mapper.solr_name('label')] }
    end

  end
end
