Hasset vocab downloaded under CC-BY-NC-ND 4.0

https://hasset.ukdataservice.ac.uk/hasset-guide/obtaining-hasset.aspx
https://hasset.ukdataservice.ac.uk/download/HassetTriples.zip

```ruby
# /home/conor/Workspace/dri-app-tracker/db/seeds/hasset_authority.rb
# def self.add_hasset_authority

# didn't resolve after over 15 minutes, stay with just prefLabel for now
repo = RDF::Repository.load(hasset_path)
client = SPARQL::Client.new(repo)
query_text = "
  PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
  SELECT ?uri ?label
  WHERE {
    ?uri ?predicate ?label .
      { ?uri skos:prefLabel ?label . }
    UNION
      { ?uri skos:altLabel ?label . }
  }
"
results = client.query(query_text)
```
