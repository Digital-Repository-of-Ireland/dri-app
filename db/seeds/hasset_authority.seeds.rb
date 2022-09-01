require 'rdf'
require 'rdf/rdfxml'
require 'rdf/vocab/skos'

def add_hasset_authority
  return if Qa::LocalAuthority.exists?(name: 'hasset')
  # https://www.rubydoc.info/gems/qa/1.2.0#local-sub-authorities
  hasset_graph = RDF::Graph.load(hasset_data_path)

  # skos: prefLabel, altLabel
  query = RDF::Query.new({ subject: { RDF::Vocab::SKOS.prefLabel => :label } })

  # 7626 terms with SKOS:prefLabel, would be slow as yml file
  results = query.execute(hasset_graph)
  hasset_authority = Qa::LocalAuthority.find_or_create_by(name: 'hasset')

  with_silent_failure do
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

def remove_hasset_authority
  hasset_authority = Qa::LocalAuthority.find_by(name: 'hasset')
  Qa::LocalAuthorityEntry.where(local_authority: hasset_authority).delete_all
  Qa::LocalAuthority.where(name: 'hasset').delete_all
end

def hasset_data_path
  Rails.root.join('app', 'authorities', 'qa', 'data', 'Hasset20190123.rdf')
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
add_hasset_authority
