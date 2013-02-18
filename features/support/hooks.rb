Before('@collections') do
  clean_repo
end

After('@collections') do
  clean_repo
end

Before('@users') do
  DatabaseCleaner.start
end

After('@users') do |scenario|
  DatabaseCleaner.clean
end
