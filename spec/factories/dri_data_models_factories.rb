FactoryGirl.define do

  factory(:audio, :class => DRI::Model::Audio) do
    title                  "An Audio Title"
    rights                 "This is a statement about the rights associated with this object"
    presenter              ["Collins, Michael"]
    guest                  ["DeValera, Eamonn", "Connolly, James"]
    language               "ga"
    description            "This is an Audio file"
    broadcast_date         "1916-04-01"
    creation_date          "1916-01-01"
    source                 ["CD nnn nuig"]
    geographical_coverage  ["Dublin"]
    temporal_coverage      ["1900s"]
    subject                ["Ireland","something else"]
  end

  factory(:pdfdoc, :class => DRI::Model::Pdfdoc) do
    title                  "A PDF Title"
    rights                 "This is a statement about the rights associated with this object"
    author                 ["Collins, Michael"]
    editor                 ["DeValera, Eamonn", "Connolly, James"]
    language               "ga"
    description            "This is a PDF document" 
    creation_date          "1916-01-01"
    source                 ["CD nnn nuig"]
    geographical_coverage  ["Dublin"]
    temporal_coverage      ["1900s"]
    subject                ["Ireland","something else"]
  end

  factory(:collection, :class => DRI::Model::Collection) do
    title                  "A collection"
    description            "This is a Collection"
    publisher              "RnaG"
  end

end
