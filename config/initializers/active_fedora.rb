
ActiveFedora::Fedora.class_eval do
  def connection
    @connection ||= begin
      build_connection
    end
  end
end
