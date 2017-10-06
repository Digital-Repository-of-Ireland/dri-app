module DRI::Formatters
  class Preservation < DRI::Formatters::Rdf

    def initialize(object_doc, options = {})
      fields = options[:fields].presence
      @object_doc = object_doc
      
      build_graph
    end

    def build_graph
      graph << [uri, RDF::FOAF.primaryTopic, RDF::URI("#{uri}#id")]
      graph << [uri, RDF.type, RDF::FOAF.Document]
      
      add_licence
      
      add_metadata
      add_hierarchy
      add_relationships
      add_assets
     
      graph
    end

    def add_metadata
      id = "#{uri}#id"

      graph << [RDF::URI.new(id), RDF.type, RDF::Vocab::DCMIType.Collection] if @object_doc.collection?
      graph << [RDF::URI.new(id), RDF::URI("info\:fedora/fedora-system\:def/model#hasModel"), RDF::Literal.new(@object_doc['active_fedora_model_ssi'])]
      graph << [RDF::URI.new(id), RDF::DC.creator, RDF::Literal.new(@object_doc['depositor_tesim'].first)]
      graph << [RDF::URI.new(id), RDF::DC.contributor, RDF::Literal.new(committer)]
      graph << [RDF::URI.new(id), RDF::DC.created, RDF::Literal.new(@object_doc['system_create_dtsi'])]
      graph << [RDF::URI.new(id), RDF::DC.modified, RDF::Literal.new(modified_at)]
    end

    def add_assets
      assets = @object_doc.assets
      
      assets.each do |a| 
        id = "#{base_uri}#{object_file_path(a['id'])}#id"
        graph << [RDF::URI("#{uri}#id"), RDF::DC.hasPart, RDF::URI.new(id)]
        graph << [RDF::URI.new(id), RDF::FOAF.topic, RDF::URI("#{uri}#id")]
        graph << [RDF::URI.new(id), RDF::DC.isPartOf, RDF::URI("#{uri}#id")]
      end
    end

    def version
      @version ||= VersionCommitter.where(obj_id: @object_doc.id).order('version_id ASC').last
    end

    def committer
      version.committer_login
    end

    def modified_at
      version.created_at.iso8601
    end
  end
end
