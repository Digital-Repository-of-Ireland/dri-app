module Types
  class DateTimeType < Types::BaseScalar
    def self.coerce_input(value, _context)
      # Time.zone.parse(value) # adds Z, DateTime +offset
      DateTime.parse(value)
    end

    def self.coerce_result(value, _context)
      # 2018-11-22 13:34:55 +0000 # iso_date_time_utc
      if value.kind_of?(String)
        value = self.coerce_input(value, _context)
      end
      value.utc.iso8601
    end
  end
end
