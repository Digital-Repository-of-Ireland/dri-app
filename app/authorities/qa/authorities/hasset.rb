module Qa::Authorities
  class Hasset < Qa::Authorities::Base
    def search(_q)
      # hasset labels are all uppercase, so make query case insensitive
      results = all.where('lower(label) LIKE ?', "#{_q.downcase}%")
      results.map { |result| { label: result.label, id: result.uri } }
    end

    def all
      hasset_authority = Qa::LocalAuthority.find_by(name: 'hasset')
      Qa::LocalAuthorityEntry.where(local_authority: hasset_authority)
    end
  end
end
