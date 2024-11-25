DRI::Noid.module_eval do
  def service
    @service ||= DRI::Noid::Service.new
  end
end
