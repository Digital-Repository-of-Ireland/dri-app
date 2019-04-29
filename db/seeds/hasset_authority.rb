require 'rdf'
require 'rdf/vocab/skos'

module Seeds
  def self.add_hasset_authority
    # https://www.rubydoc.info/gems/qa/1.2.0#local-sub-authorities
    hasset_graph = RDF::Graph.load(self.hasset_data_path, format: :rdf_xml)

    # skos: prefLabel, altLabel
    query = RDF::Query.new({ subject: { RDF::Vocab::SKOS.prefLabel => :label } })

    # 7626 terms with SKOS:prefLabel, would be slow as yml file
    results = query.execute(hasset_graph)
    hasset_authority = Qa::LocalAuthority.find_or_create_by(name: 'hasset')

    self.with_silent_failure do
      results.each do |result|
        qa_args = {
                    local_authority: hasset_authority,
                    label: result.label.to_s,
                    uri: result.subject.to_s
                  }
        Qa::LocalAuthorityEntry::create(qa_args)
      end
    end
  end

  def self.remove_hasset_authority
    hasset_authority = Qa::LocalAuthority.find_by(name: 'hasset')
    Qa::LocalAuthorityEntry::delete_all(local_authority: hasset_authority)
    Qa::LocalAuthority.delete_all(name: 'hasset')
  end

  def self.hasset_data_path
    Rails.root.join('app', 'authorities', 'qa', 'data', 'Hasset20190123.rdf')
  end

  # send warning to stdout and log errors rather than failing rake task
  # (and by extension, the build since db:seed must pass)
  def self.with_silent_failure(&_block)
    warned = false

    begin
      yield(_block)
    rescue => e
      unless warned
        warn(e)
        warned = true
      end

      Rails.logger.error(e)
    end
  end
end
