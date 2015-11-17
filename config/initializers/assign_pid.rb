require "sufia/noid.rb"

Sufia::Noid.module_eval do

  def assign_id
    if Sufia.config.enable_noids
      id = nil
      id = new_id until id

      id
    end
  end

  def new_id
    id = service.mint
    ActiveFedora::Base.find(id)

    id
  rescue Ldp::Gone
    Rails.logger.error "Tombstone ID #{id}"
    nil
  rescue ActiveFedora::ObjectNotFoundError
    id
  end

end

