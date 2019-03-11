
Before('not @javascript') do
  page.driver.browser.header('Accept-Language', 'en')
end

Before('@stub_requests') do
  # stub questioning authority autocomplete requests
  qa_base = /http:\/\/(localhost|127.0.0.1):\d+\/qa\/search/
  loc_base = /#{qa_base}\/loc\/subjects/
  logainm_base = /#{qa_base}\/logainm\/subjects/
  nuts3_base = /#{qa_base}\/nuts3\/subjects/
  oclc_base = /#{qa_base}\/assign_fast\/all/
  unesco_base = /#{qa_base}\/nuts3\/subjects/

  # use puffing billy to stub responses from lod endpoints
  [loc_base, logainm_base, nuts3_base, oclc_base, unesco_base].each do |regex_base|
    proxy.stub(/#{regex_base}.*/).and_return(json: [])
    # pass param through (i.e. whatever the user types, return that as an autocomplete result)
    proxy.stub(/#{regex_base}\?q=(.*)/i).and_return(Proc.new { |params, headers, body, url, method|
      # labels at real endpoints are usually capitalized
      label = params['q'].first.split(/\s+/).map {|v| v.capitalize }.join(' ')
      uri = "http://example.com/#{params['q'].first.gsub(/\s+/, '_')}"
      {
        code: 200,
        json: [ { label: label, id: uri } ]
      }
    })
  end
end

After do
  FileUtils.remove_dir(@tmp_assets_dir, force: true)
end

Before('@random_pid') do
  @random_pid = SecureRandom.hex(5)
end

After('@random_pid') do
  storage = StorageService.new
  storage.delete_bucket("o"+@random_pid)

  @random_pid = ""
end

After('@api') do
  buckets = ['apitest1', 'apitest2']

  storage = StorageService.new

  buckets.each { |bucket| storage.delete_bucket(bucket) }
end

After('@read_only') do
  Settings.read_only = false
end

# can't use around hook to catch expectation failure because it gets rescued internally
After do |scenario|
  # using byebug stop interaction with browser, just sleep on failure
  if ENV['headless']&.downcase&.strip == 'false' && scenario.failed?
    sleeptime = 600
    STDOUT.puts("\nScenario failed. Sleeping for #{sleeptime} seconds.")
    sleep(sleeptime)
  end
end
