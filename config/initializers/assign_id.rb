require 'sufia/noid.rb'

Sufia::Noid.module_eval do

  def service
    @service ||= DRI::Noid::Service.new
  end

end
