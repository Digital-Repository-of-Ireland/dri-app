# frozen_string_literal: true
SOLR_TEST_URL ||= "http://127.0.0.1:#{ENV['SOLR_TEST_PORT'] || 8983}/solr/test"
RSpec.configure do |config|
  config.before(:all) do
    client = RSolr.connect(url: SOLR_TEST_URL)
    client.delete_by_query("*:*", params: { softCommit: true })
  end
end
