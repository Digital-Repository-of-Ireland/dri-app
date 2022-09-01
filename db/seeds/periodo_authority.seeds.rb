require 'rdf'
require 'rdf/turtle'
require 'rdf/vocab/skos'

def add_periodo_authority
  # https://www.rubydoc.info/gems/qa/1.2.0#local-sub-authorities
  return if Qa::LocalAuthority.exists?(name: 'periodo')
  periodo_graph = RDF::Graph.load(periodo_data_path)

  # skos: prefLabel, altLabel
  query = RDF::Query.new({ subject: { RDF::Vocab::SKOS.prefLabel => :label } })

  # 7626 terms with SKOS:prefLabel, would be slow as yml file
  results = query.execute(periodo_graph)
  periodo_authority = Qa::LocalAuthority.find_or_create_by(name: 'periodo')

  with_silent_failure do
    results.each do |result|
      qa_args = {
                  local_authority: periodo_authority,
                  label: result.label.to_s,
                  uri: result.subject.to_s
                }
      Qa::LocalAuthorityEntry::create(qa_args)
    end
  end
end

def remove_periodo_authority
  periodo_authority = Qa::LocalAuthority.find_by(name: 'periodo')
  Qa::LocalAuthorityEntry.where(local_authority: periodo_authority).delete_all
  Qa::LocalAuthority.where(name: 'periodo').delete_all
end

def periodo_data_path
  Rails.root.join('app', 'authorities', 'qa', 'data', 'periodo_dataset.ttl')
end

# send warning to stdout and log errors rather than failing rake task
# (and by extension, the build since db:seed must pass)
def with_silent_failure(&_block)
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

puts "Seeding: #{__FILE__}"
add_periodo_authority
