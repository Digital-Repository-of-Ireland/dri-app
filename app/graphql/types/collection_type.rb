module Types
  class CollectionType < BaseObject
    # TODO handle access levels, currently only published

    # generated
    field :id, ID, null: false
    # should this be null false?, shouldn't be able to publish without published_at set
    field :published_at, DateTimeType, null: true # 2019-01-15T15:20:44Z
    field :create_date, DateTimeType, null: false # Thu, 22 Nov 2018 13:34:56 +0000
    field :modified_date, DateTimeType, null: false # Thu, 22 Nov 2018 13:34:56 +0000
    field :root_collection, [ID], null: false # self.id if collection is root

    # required: title, creators, date, creation date, description, rights 
    field :title, [String], null: false
    field :creator, [String], null: false

    # organisation should be set to be published: null: false
    field :depositing_institute, String, null: true

    # optional
    field :language, [String], null: true
    field :licence, String, null: true
    field :contributor, [String], null: true
    # note published_date is free text input from user, published_at is system generated date
    field :published_date, [String], null: true 
    field :relation, [String], null: true
    field :coverage, [String], null: true
    field :temporal_coverage, [String], null: true
    field :geographical_coverage, [String], null: true
    field :subject, [String], null: true
    field :qdc_id, [String], null: true
    # language, licence, contributors, published date, related materials, coverages, 
    # subjects (places), subjects (temporal), subjects, identifiers, 
  end
end
