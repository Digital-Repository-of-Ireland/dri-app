# rswag / api shared contexts
shared_context 'rswag_include_json_spec_output' do |example_name='application/json'|
  after do |example|
    example.metadata[:response][:examples] = {
      example_name => JSON.parse(
        response.body,
        symbolize_names: true
      )
    }
  end
end

shared_context 'rswag_include_xml_spec_output' do |example_name='application/xml'|
  after do |example|
    example.metadata[:response][:examples] = {
      example_name => Nokogiri::XML(response.body)
    }
  end
end

shared_context 'rswag_user_with_collections' do |status: 'draft', num_collections: 2, num_objects: 2, subcollection: true, doi: true, docs: true, object_type: :sound|
  include_context 'tmp_assets'
  before(:each) do
    @licence = Licence.create(
      name: 'test', description: 'this is a test', url: 'http://example.com'
    )

    @example_user = create_user
    @collections  = []
    @dois         = []
    @docs         = []
    @institute    = create_institute(status)

    num_collections.times do |i|
      collection = create_collection_for(@example_user, status: status)
      collection.licence = @licence.name

      if docs
        doc = FactoryBot.create(:documentation)
        collection.documentation_object_ids = doc.id
        @docs << doc
      end

      num_objects.times do |j|
        object = create_object_for(
          @example_user,
          status: status,
          title: "not a duplicate #{i}#{j}",
          type: object_type
        )
        object.depositing_institute = @institute.name if @institute
        collection.governed_items << object
        @dois << DataciteDoi.create(object_id: object.id) if doi
      end
      collection.depositing_institute = @institute.name if @institute
      collection.manager_users = [@example_user]
      collection.published_at = DateTime.now.strftime("%Y-%m-%d")
      collection.save
      @collections << collection
    end
    @collections << create_subcollection_for(@example_user) if subcollection
    sign_out_all # just to make sure requests aren't using session
  end
  after(:each) do
    @licence.destroy
    @institute.delete if @institute
    @example_user.delete
    @dois.map(&:delete)
    # issue with nested examples e.g iiif_spec
    # possibly check for ldp gone before delete?
    # @collections.map(&:delete)
    @collections.each do |c|
      # try to destroy collection if it still exists, otherwise do nothing
      c.destroy rescue nil
    end
  end
end

shared_context 'sign_out_before_request' do
  before do |example|
    sign_out_all
    submit_request(example.metadata)
  end
end

# this context depends on @collection existing
# and the first collection having more than one governed object
# i.e. should be within rswag_user_with_collections
# does not work with aggregate fields e.g. person
# adjacent field could be creator, which is part of person
# @param [String] field
# @param [Array] all_fields
# @param [Symbol] search_param
shared_context 'catch search false positives' do |field, all_fields, search_param|
  before do
    # mode is objects, so ignore subcollections
    @objects = @collections.first.governed_items.reject(&:collection?)
    raise ArgumentError, 'less than 2 objects in collection' unless @objects.count >= 2

    @objects[0].send("#{field}=", bind_search_param)
    @objects[0].save

    # treat fields like circular list, pick adjacent field so build is reproducible
    idx = all_fields.find_index(field)
    @adjacent_field = all_fields[(idx + 1) % all_fields.length]

    raise ArgumentError, 'selected same field' unless @adjacent_field != field

    @objects[1].send("#{@adjacent_field}=", bind_search_param)
    @objects[1].save
    # @collections.map(&:governed_items).flatten.map(&:title)
    # @collections.map(&:governed_items).flatten.map(&:"#{field}")
  end

  after do
    # reset the values
    # TODO: is it worth regenerating collections for each spec?
    # would avoid this edge case requiring reset
    # @collections.map(&:governed_items).flatten.reject(&:collection?).each do |gov_obj|
    @objects.each do |gov_obj|
      gov_obj.send("#{field}=", %w[after_search_test])
      gov_obj.send("#{@adjacent_field}=", %w[after_search_test])
      gov_obj.save
    end
  end
end
