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
    service.mint
  rescue Ldp::Gone
    nil
  end

end
