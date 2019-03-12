module Resolvers
  class ObjectsSearch < BaseResolver
    def all_objects(kwargs: {})
      # # false not the same as not true
      # # find cases where item is type object, but does not have is_collection_sim: false
      # # not clause doesn't work with active fedora unless some other clause at start
      # ['*:* !is_collection_sim:true', 'is_collection_sim:false'].map do |field|
      #   DRI::QualifiedDublinCore.where(field).length
      # end
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'false',
        status: 'published',
        **kwargs
      )
    end

    scope do
      all_objects
    end

    type types[Types::ObjectType]

    # inline input type definition for the advance filter
    class ObjectFilter < ::Types::BaseInputObject
      Types::ObjectType.fields.keys.each do |field_name|
        argument :"#{field_name.underscore}_contains", String, required: false
        argument :"#{field_name.underscore}_is", String, required: false
        # TODO: escape solr chars for _is query? e.g. description_is:*test*
      end
    end

    option :filter, type: ObjectFilter, with: :apply_filter
    option :first, type: types.Int, 
                   default: blacklight_config.default_per_page, 
                   with: :apply_first
    option :skip, type: types.Int, with: :apply_skip

  end
end
