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
  AWS.config(s3_endpoint: Settings.S3.server, :access_key_id => Settings.S3.access_key_id, :secret_access_key => Settings.S3.secret_access_key)
  s3 = AWS::S3.new(ssl_verify_peer: false)
  bucket = s3.buckets["o"+@random_pid]
  bucket.delete!

  @random_pid = ""
end

After('@api') do
  buckets = ['apitest1', 'apitest2']
  AWS.config(s3_endpoint: Settings.S3.server, :access_key_id => Settings.S3.access_key_id, :secret_access_key => Settings.S3.secret_access_key)
  s3 = AWS::S3.new(ssl_verify_peer: false)

  buckets.each do |bucket|
    begin
      bucket = s3.buckets[bucket]
      bucket.delete!
    rescue Exception
    end
  end
end

