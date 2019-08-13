After do
  FileUtils.remove_dir(@tmp_assets_dir, force: true)
  Warden.test_reset!
end

# Before do
#   # standardize window size (generic, runs on any driver, but slower than passing in config env.rb)
#   Capybara.page.driver.browser.manage.window.resize_to(1200, 800)
# end

Before('@javascript') do
  @javascript_driver = true
end

Before('not @javascript') do
  page.driver.browser.header('Accept-Language', 'en')
end

Before('@stub_qa') do
  %w(Hasset Nuts3 Logainm Unesco Loc::GenericAuthority).each do |auth|
    allow_any_instance_of("Qa::Authorities::#{auth}".constantize).to receive(:search) do |_instance, arg|
      label = arg.split(/\s+/).map {|v| v.capitalize }.join(' ')
      uri = "http://example.com/#{arg.gsub(/\s+/, '_')}"
      [ { label: label, id: uri } ]
    end
  end
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

Before('@enforce_cookies') do
  ENV['enforce_cookies'] = 'true'
end

After('@enforce_cookies') do
  ENV['enforce_cookies'] = 'false'
end

# can't use around hook to catch expectation failure because it gets rescued internally
if ENV['headless']&.downcase&.strip == 'false'
  After do |scenario|
    if scenario.failed?
      # using byebug stop interaction with browser, just sleep on failure
      sleeptime = 600 # 10 minutes
      STDOUT.puts("\nScenario failed. Sleeping for #{sleeptime} seconds.")
      sleep(sleeptime)
    end
  end
end
