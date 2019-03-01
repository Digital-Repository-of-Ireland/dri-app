class DriAppSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  def self.resolve_type(_type, object, _ctx)
    type_class = "::Types::#{object.class}Type".safe_constantize

    raise ArgumentError, "Cannot resolve type for class #{object.class.name}" unless type_class.present?

    type_class
  end
end
