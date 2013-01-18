Given /^a Digital Object$/ do
  @digital_object = DRI::Model::Audio.new(:pid => NuigRnag::IdService.mint)
end

When /^I commit the Digital Object$/ do
  @digital_object.save
end

Then /^I should be given a PID from the digital repository$/ do
  @digital_object.id.should =~ /^#{NuigRnag::Application.config.id_namespace}:\w\w\d\d\w\w\d\d\w$/
end

When /^I add (.*?) metadata$/ do |type|
  if type == "valid"
    filename = "valid_metadata.xml"
  else
    filename = "metadata_no_rights.xml"
  end

  @tmp_xml = Nokogiri::XML(File.new(File.join(cc_fixture_path, filename)).read)

  if @digital_object.datastreams.has_key?("descMetadata")
    @digital_object.datastreams["descMetadata"].ng_xml = @tmp_xml
  else
    ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
    @digital_object.add_datastream ds, :dsid => 'descMetadata'
  end
end

When /^I add an invalid asset$/ do
  datastream = "masterContent"

  count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d", { :f => @digital_object.id, :d => datastream } ]).count

  dir = Rails.root.join('dri_files').join(@digital_object.id).join(datastream+count.to_s)

  @filedata = Rack::Test::UploadedFile.new(File.join(cc_fixture_path,'invalid_asset.mp3'), 'audio/mp3')

  @file = LocalFile.new
  @file.add_file @filedata, {:fedora_id => @digital_object.id, :ds_id => datastream, :directory => dir.to_s, :version => count}
  @file.save!

  @url = url_for :controller=>"files", :action=>"show", :id=>@digital_object.id
  @digital_object.add_file_reference datastream, :url=>@url, :mimeType=>@file.mime_type
end

Then /^I should get an invalid Digital Object$/ do
  @digital_object.should_not be_valid
end
