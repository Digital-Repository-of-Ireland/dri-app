OAI::Provider::Metadata::DublinCore.class_eval do
  def valid?(record)
    record.published?
  end
end
