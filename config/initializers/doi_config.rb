config = Rails.root.join('config', 'doi.yml')

DoiConfig = File.exist?(config) ? OpenStruct.new(YAML.load_file(config, aliases: true)[Rails.env]) : nil
