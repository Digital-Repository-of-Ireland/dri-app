task :localefiles do
  require 'yaml'

  ga_file = Rails.root.to_s + "/" + ENV['file'].to_s
  en_file = ga_file.gsub(/ga\.yml/, "en.yml")

  slave = YAML::load_file ga_file
  master = YAML::load_file en_file

  merged = master["en"].deep_merge(slave["ga"])

  final = { "ga" => merged } # remove other keys
  File.open(ga_file, 'w') do |file|
    file.write final.to_yaml.gsub(/\s+$/, '')
  end

  puts "+ merged #{ga_file} with #{en_file}"

end
