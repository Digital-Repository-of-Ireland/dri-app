#Before do
#  DatabaseCleaner.start
#end

Before('~@javascript') do
  page.driver.browser.header('Accept-Language', 'en')
end

After do
  #DatabaseCleaner.clean
  clean_repo
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

