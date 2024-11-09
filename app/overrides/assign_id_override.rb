require 'dri/noid.rb'

DRI::Noid.module_eval do

  def service
    puts "service"
    @service ||= DRI::Noid::Service.new
  end

end
