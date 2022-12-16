config = Rails.root.join('config', 'doi.yml')

DoiConfig = File.exists?(config) ? OpenStruct.new(YAML.load_file(config, aliases: true)[Rails.env]) : nil
