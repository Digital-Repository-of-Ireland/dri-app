module DRI
  class MyCollectionsPresenter < CollectionPresenter

    def children
      @children ||= document.children(100).select { |child| child.published? || (current_user.is_admin? || can?(:edit, doc)) }
    end

    def displayfiles
      @displayfiles ||= files.reject { |file| file.preservation_only? }
    end

    private

      def files
        @files ||= document.assets(true).sort_by! { |f| f[ActiveFedora.index_field_mapper.solr_name('label')] }
      end

  end
end
