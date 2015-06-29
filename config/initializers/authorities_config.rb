config = Rails.root.join('config', 'authorities.yml')

AuthoritiesConfig = File.exists?(config) ? OpenStruct.new(YAML.load_file(config)[Rails.env]) : nil
