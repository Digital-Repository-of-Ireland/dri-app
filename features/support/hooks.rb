Before('@collections', '@construct', '@web') do
  clean_repo
end

After('@collections', '@construct', '@web') do
  clean_repo
end

Before('@users') do
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.start
end

After('@users') do
  DatabaseCleaner.clean
end
