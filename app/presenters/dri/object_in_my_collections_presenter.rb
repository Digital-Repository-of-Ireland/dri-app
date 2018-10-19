module DRI
  class ObjectInMyCollectionsPresenter < ObjectPresenter

    delegate :url_for, :object_file_url, :current_user, :can?, to: :@view

    def depositing_organisations
      @depositing_organisations ||= Institute.where(depositing: true).pluck(:name)
    end

    def displayfiles(files)
      @displayfiles ||= files.reject { |file| file.preservation_only? }
    end

    def relationships
      @relationships ||= object_relationships
    end

    def unassigned_organisations
      @unassigned_organisations ||= all_organisations - current_collection_organisations - [depositing_organisation.try(:name)]
    end

    def assigned_organisations
      @removal_institutes = current_collection_organisations - [depositing_organisation.try(:name)]
    end

    private

      def object_relationships
        relationships = document.object_relationships
        filtered_relationships = {}

        relationships.each do |key, array|
          filtered_array = array.select { |item| item[1].published? || (current_user.is_admin? || can?(:edit, item[1])) }
          unless filtered_array.empty?
            filtered_relationships[key] = Kaminari.paginate_array(filtered_array).page(params[key.downcase.gsub(/\s/, '_') << '_page']).per(4)
          end
        end

        filtered_relationships
      end

      def all_organisations
        @all_organisations ||= Institute.all.pluck(:name)
      end

      def current_collection_organisations
        @current_collection_organisations ||= organisations.map(&:name)
      end
  end
end
