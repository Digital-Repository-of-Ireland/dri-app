Before do
  DatabaseCleaner.start
end

Before('~@javascript') do
  page.driver.browser.header('Accept-Language', 'en')
end

After do
  DatabaseCleaner.clean
  clean_repo
end

Before('@random_pid') do
  @random_pid = SecureRandom.hex(5)
end

After('@random_pid') do
  storage = Storage::S3Interface.new
  storage.delete_bucket("o"+@random_pid)

  @random_pid = ""
end

After('@api') do
  buckets = ['apitest1', 'apitest2']

  storage = Storage::S3Interface.new
  buckets.each do |bucket|
    storage.delete_bucket(bucket)
  end
end

