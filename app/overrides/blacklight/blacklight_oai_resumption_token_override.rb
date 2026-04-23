BlacklightOaiProvider::ResumptionToken.class_eval do
  def encode_conditions
    return "" if last_str.nil? || last_str.to_s.strip.eql?("")

    encoded_token = @prefix.to_s.dup
    encoded_token << ".s(#{set})" if set
    if self.from
      if self.from.respond_to?(:utc)
        encoded_token << ".f(#{self.from.utc.xmlschema})"
      else
        encoded_token << ".f(#{self.from.xmlschema})"
      end
    end
    if self.until
      if self.until.respond_to?(:utc)
        encoded_token << ".u(#{self.until.utc.xmlschema})"
      else
        encoded_token << ".u(#{self.until.xmlschema})"
      end
    end
    encoded_token << ":#{last_str}"
  end
end