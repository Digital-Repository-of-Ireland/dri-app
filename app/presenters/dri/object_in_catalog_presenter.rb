module DRI
  class ObjectInCatalogPresenter < ObjectPresenter

    delegate :object_file_url, to: :@view

    def displayfiles(assets)
      @displayfiles = assets
    end

    def relationships
      @relationships ||= object_relationships
    end

    private

      def object_relationships
        relationships = document.object_relationships
        filtered_relationships = {}

        relationships.each do |key, array|
          filtered_array = array.select { |item| item[1].published? }
          unless filtered_array.empty?
            filtered_relationships[key] = Kaminari.paginate_array(filtered_array).page(params[key.downcase.gsub(/\s/, '_') << '_page']).per(4)
          end
        end

        filtered_relationships
      end
  end
end
