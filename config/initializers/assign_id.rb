require 'sufia/noid'
require 'rest-client'

Sufia::Noid.module_eval do

  def assign_id
    new_id if Sufia.config.enable_noids
  end

  def new_id
    attempts = 4

    id = service.mint
    until attempts == 0
      if id_valid?(id)
        valid = true
        break
      end
      
      id = service.mint
      attempts -= 1
    end  

    valid ? id : nil
  end

  def client
    @client ||= RestClient::Resource.new(ActiveFedora.fedora_config.credentials[:url],
              user: ActiveFedora.fedora_config.credentials[:user],
              password: ActiveFedora.fedora_config.credentials[:password])
  end

  def id_valid?(id)
    client[ActiveFedora::Base.id_to_uri(id).split(ActiveFedora.fedora_config.credentials[:url])[1]].head
    false
  rescue RestClient::ResourceNotFound
    true
  rescue RestClient::Gone
    false
  end
end
