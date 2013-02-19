Before do
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
  clean_repo
end
