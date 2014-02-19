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
  AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                      :access_key_id => Settings.S3.access_key_id,
                                      :secret_access_key => Settings.S3.secret_access_key)
  AWS::S3::S3Object.delete("dri:o"+@random_pid+"_mp3_web_quality.mp3", "o"+@random_pid)
  AWS::S3::Bucket.delete("o"+@random_pid)
  AWS::S3::Base.disconnect!()

  @random_pid = ""
end

After('@api') do
  buckets = ['apitest1', 'apitest2']
  AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                     :access_key_id => Settings.S3.access_key_id,
                                     :secret_access_key => Settings.S3.secret_access_key)
  buckets.each do |bucket|
    begin
      AWS::S3::Bucket.delete(bucket, :force => true)
    rescue Exception
    end
  end
  AWS::S3::Base.disconnect!()
end

