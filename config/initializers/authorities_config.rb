config = Rails.root.join('config', 'authorities.yml')

AuthoritiesConfig = File.exist?(config) ? OpenStruct.new(YAML.load_file(config, aliases: true)[Rails.env]) : nil
