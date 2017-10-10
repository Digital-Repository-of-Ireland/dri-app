FactoryGirl.define do

  factory(:sound, :class => DRI::QualifiedDublinCore) do
    title                  ["An Audio Title"]
    rights                 ["This is a statement about the rights associated with this object"]
    role_hst               ["Collins, Michael"]
    contributor            ["DeValera, Eamonn", "Connolly, James"]
    language               ["ga"]
    description            ["This is an Audio file"]
    published_date         ["1916-04-01"]
    creation_date          ["1916-01-01"]
    source                 ["CD nnn nuig"]
    geographical_coverage  ["Dublin"]
    temporal_coverage      ["1900s"]
    subject                ["Ireland","something else"]
    resource_type                   ["Sound"]
    object_version          '1'

    after(:create) do |sound|
      VersionCommitter.create(obj_id: sound.noid, committer_login: sound.depositor, version_id: '1')

      preservation = Preservation::Preservator.new(sound)
      preservation.preserve(false, ['descMetadata','properties'])
    end
  end

  factory(:audio, :class => DRI::QualifiedDublinCore) do
    title                  ["An Audio Title"]
    rights                 ["This is a statement about the rights associated with this object"]
    role_hst               ["Collins, Michael"]
    contributor            ["DeValera, Eamonn", "Connolly, James"]
    language               ["ga"]
    description            ["This is an Audio file"]
    published_date         ["1916-04-01"]
    creation_date          ["1916-01-01"]
    source                 ["CD nnn nuig"]
    geographical_coverage  ["Dublin"]
    temporal_coverage      ["1900s"]
    subject                ["Ireland","something else"]
    resource_type                   ["Sound"]
    object_version          '1'

     after(:create) do |audio|
      preservation = Preservation::Preservator.new(audio)
      preservation.preserve(false, ['descMetadata','properties'])
    end
  end

  factory(:text, :class => DRI::QualifiedDublinCore) do
    title                  ["A PDF Title"]
    rights                 ["This is a statement about the rights associated with this object"]
    role_aut               ["Collins, Michael"]
    role_edt                ["DeValera, Eamonn", "Connolly, James"]
    language               ["ga"]
    description            ["This is a PDF document"]
    creation_date          ["1916-01-01"]
    source                 ["CD nnn nuig"]
    geographical_coverage  ["Dublin"]
    temporal_coverage      ["1900s"]
    subject                ["Ireland","something else"]
    resource_type                   ["Text"]
  end

  factory(:collection, :class => DRI::QualifiedDublinCore) do
    title                  ["A collection"]
    description            ["This is a Collection"]
    rights                 ["This is a statement about the rights associated with this object"]
    creator                ["A. User"]
    publisher              ["RnaG"]
    resource_type          ["Collection"]
    creation_date          ["1916-01-01"]
    published_date         ["1916-01-02"]
    object_version          '1'

    after(:create) do |collection|
      VersionCommitter.create(obj_id: collection.noid, committer_login: collection.depositor, version_id: '1')

      preservation = Preservation::Preservator.new(collection)
      preservation.preserve(false, ['descMetadata','properties'])
    end
  end

end
