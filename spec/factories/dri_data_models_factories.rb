FactoryGirl.define do

  factory(:audio, :class => DRI::Model::Audio) do
    title                  "An Audio Title"
    rights                 "This is a statement about the rights associated with this object"
    presenter              ["Collins, Michael"]
    guest                  ["DeValera, Eamonn", "Connolly, James"]
    language               "ga"
    description           "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    broadcast_date         "1916-04-01"
    creation_date          "1916-01-01"
    source                 ["CD nnn nuig"]
    geographical_coverage  ["Dublin"]
    temporal_coverage      ["1900s"]
    subject                ["Ireland","something else"]
  end

end
