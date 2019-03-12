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
# @param [Sting] type
shared_context 'filter_test results exist' do |field: :subject, type: 'Collection'|
  before(:each) do
    filter_vals = %w[filter_test other_filter_test]
    # filter_vals.map! {|v| [v]} if DRI::QualifiedDublinCore.multiple?(field)
    multival = Types.const_get("#{type}Type").fields[field.camelize(:lower)].type.list?
    filter_vals.map! { |v| [v] } if multival

    qdc_arr = instance_variable_get("@#{type.downcase.pluralize}")

    qdc_arr.first.send("#{field}=", filter_vals.first)
    qdc_arr.first.save!

    qdc_arr.last.send("#{field}=", filter_vals.last)
    qdc_arr.last.save!
  end
end


# @param [Symbol] field
# @param [Sting] type
shared_context 'filter_test results do not exist' do |field: :subject, type: 'Collection'|
  before(:each) do
    qdc_arr = instance_variable_get("@#{type.downcase.pluralize}")
    qdc_arr.each do |col|
      filter_val = 'no_match'
      multival = Types.const_get("#{type}Type").fields[field.camelize(:lower)].type.list?
      filter_val = [filter_val] if multival

      col.send("#{field}=", filter_val)
      col.save!
    end    
  end
end
