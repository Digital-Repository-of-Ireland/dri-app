module Qa::Authorities
  class Periodo < Qa::Authorities::Base
    def search(_q)
      results = all.where('lower(label) LIKE ?', "#{_q.downcase}%")
      results.map { |result| { label: result.label, id: result.uri } }
    end

    def all
      Qa::LocalAuthorityEntry.where(local_authority: authority_object)
    end

    def authority_object
      Qa::LocalAuthority.find_by(name: 'periodo')
    end

    def empty?
      all.empty?
    end
  end
end

