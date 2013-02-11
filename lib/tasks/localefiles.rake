task :localefiles do
  masterfile = Rails.root.to_s + "/" + ENV['file'].to_s
  %x{i18s #{masterfile}}
end
