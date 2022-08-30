module DRI
  class AuthorityPresenter
    def self.vocabs
      [
        { name: "LOC Subject Headings", endpoint: "/qa/search/loc/subjects?q=" },
        { name: "LOC Names", endpoint: "/qa/search/loc/names?q=" },
        { name: "Getty Art and Architecture", endpoint: "/qa/search/getty/aat?q=" },
        { name: "Hasset", endpoint: "/qa/search/hasset/subjects?q=" },
        { name: "Homosaurus", endpoint: "/qa/search/homosaurus/subjects?q="},
        { name: "Logainm", endpoint: "/qa/search/logainm/subjects?q=" },
        { name: "Nuts3", endpoint: "/qa/search/nuts3/subjects?q=" },
        { name: "OCLC FAST", endpoint: "/qa/search/assign_fast/all?q=" },
        { name: "PeriodO", endpoint: "/qa/search/periodo/subjects?q=" },
        { name: "Unesco", endpoint: "/qa/search/unesco/subjects?q=" },
        { name: "Disable", endpoint: "na" }
      ]
    end

    def self.viewable_vocabs(source = nil)
      # remove local authorities if they are empty
      self.vocabs.reject do |h|
        h[:name] == 'Nuts3' if Qa::Authorities::Nuts3.new.empty? || source == 'temporal_coverage'
      end.reject do |h|
        h[:name] == 'Hasset' if Qa::Authorities::Hasset.new.empty?
      end.reject do |h|
        h[:name] == 'PeriodO' if Qa::Authorities::Periodo.new.empty? || source == 'geographical_coverage'
      end.reject do |h|
        h[:name] == 'Logainm' if source == 'temporal_coverage'
      end
    end
  end
end
