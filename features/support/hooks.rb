Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
  clean_repo
end
