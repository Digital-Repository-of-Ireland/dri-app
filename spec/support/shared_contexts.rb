shared_context 'tmp_assets' do
  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
end

shared_context 'collection_manager_user' do
  before(:all) do
    @login_user = FactoryBot.create(:collection_manager)
  end

  after(:all) do
    @login_user.destroy
  end
end

shared_context 'doi_config_exists' do
   before(:each) do
    stub_const(
      'DoiConfig',
      OpenStruct.new(
        { 
          :username => "user",
          :password => "password",
          :prefix => '10.5072',
          :base_url => "http://repository.dri.ie",
          :publisher => "Digital Repository of Ireland" 
        }
      )
    )
  end
end

# @param [Symbol] field
shared_context 'filter_test results exist' do |field: :subject|
  before(:each) do
    begin
      filter_vals = %w[filter_test other_filter_test]
      # filter_vals.map! {|v| [v]} if DRI::QualifiedDublinCore.multiple?(field)
      # Types::CollectionType.fields.select {|k, v| v.type.class.name.demodulize == "List"}.keys

      # field_type = Types::CollectionType.fields[field.camelize(:lower)].type
      # multival = field_type.class.name.demodulize == 'List'
      multival = Types::CollectionType.fields[field.camelize(:lower)].type.list?
      filter_vals.map! { |v| [v] } if multival

      @collections.first.send("#{field}=", filter_vals.first)
      @collections.first.save!

      @collections.last.send("#{field}=", filter_vals.last)
      @collections.last.save!
    rescue e
      require 'byebug'
      byebug
    end
  end
end


# @param [Symbol] field
shared_context 'filter_test results do not exist' do |field: :subject|
  before(:each) do
    @collections.each do |col|
      filter_val = 'no_match'
      # filter_val = [filter_val] if DRI::QualifiedDublinCore.multiple?(field)

      # field_type = Types::CollectionType.fields[field.camelize(:lower)].type
      multival = Types::CollectionType.fields[field.camelize(:lower)].type.list?
      filter_val = [filter_val] if multival

      col.send("#{field}=", filter_val)
      col.save!
    end    
  end
end
