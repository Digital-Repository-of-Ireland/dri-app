module Qa::Authorities
  class Hasset < Qa::Authorities::Base
    def search(_q)
      # hasset labels are all uppercase, so make query case insensitive
      results = all.where('lower(label) LIKE ?', "#{_q.downcase}%")
      results.map { |result| { label: result.label, id: result.uri } }
    end

    def all
      Qa::LocalAuthorityEntry.where(local_authority: authority_object)
    end

    def authority_object
      Qa::LocalAuthority.find_by(name: 'hasset')
    end

    def empty?
      all.empty?
    end
  end
end
