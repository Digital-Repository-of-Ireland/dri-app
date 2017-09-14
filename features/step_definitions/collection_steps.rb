include DRI::MetadataBehaviour

Given /^a collection with(?: pid "(.*?)")?(?: (?:and )?title "(.*?)")?(?: created by "(.*?)")?$/ do |pid, title, user|
  pid = @random_pid if (pid.nil? || pid == "random")
  @collection = DRI::QualifiedDublinCore.new(noid: pid)
  @collection.title = title ? [title] : [SecureRandom.hex(5)]
  @collection.description = [SecureRandom.hex(20)]
  @collection.rights = [SecureRandom.hex(20)]
  @collection.type = ["Collection"]
  @collection.creation_date = ["2000-01-01"]
  user ||= 'test'
  if user
    email = "#{user}@#{user}.com"
    User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png')) if User.find_by_email(email).nil?

    @collection.depositor = User.find_by_email(email).to_s
    @collection.manager_users_string=User.find_by_email(email).to_s
    @collection.discover_groups_string="public"
    @collection.read_groups_string="registered"
    @collection.creator = ["#{user}@#{user}.com"]
  end
  @collection.master_file_access="private"
  @collection.status = 'draft'
  @collection.save
  expect(@collection.governed_items.count).to be == 0

  group = UserGroup::Group.new(:name => @collection.noid,
                              :description => "Default Reader group for collection #{@collection.id}")
  group.save
end


Given /^a Digital Object(?: with)?(?: pid "(.*?)")?(?:(?: and)? title "(.*?)")?(?:, description "(.*?)")?(?:, type "(.*?)")?(?: created by "(.*?)")?(?: in collection "(.*?)")?/ do |pid, title, desc, type, user, coll|
  pid = @random_pid if (pid == "random")
  if pid
    @digital_object = DRI::QualifiedDublinCore.create(noid: pid)
  else
    @digital_object = DRI::DigitalObject.with_standard(:qdc)
  end
  @digital_object.title = title ? [title] : ["Test Object"]
  @digital_object.type = type ? [type] : ["Sound"]
  @digital_object.description = desc ? [desc] : ["A test object"]

  user ||= 'test'
  if user
    email = "#{user}@#{user}.com"
    User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png')) if User.find_by_email(email).nil?

    @digital_object.depositor=User.find_by_email(email).to_s
    @digital_object.manager_users_string=User.find_by_email(email).to_s
    @digital_object.creator = ["#{user}@#{user}.com"]
  end
  @digital_object.rights = ["This is a statement of rights"]
  @digital_object.creation_date = ["2000-01-01"]
  @digital_object.status = 'draft'
  
  if coll.nil?
    coll = @collection.noid unless @collection.nil?
  end
    
  @digital_object.governing_collection = DRI::Identifier.retrieve_object(coll) if coll

  checksum_metadata(@digital_object)
  @digital_object.save!

  preservation = Preservation::Preservator.new(@digital_object)
  preservation.preserve(false, false, ['descMetadata','properties'])
end

Given /^the object(?: with pid "(.*?)")? is in the collection(?: with pid "(.*?)")?$/ do |objid,colid|
  if objid
    object = DRI::Identifier.retrieve_object(objid)
  else
    object = @digital_object
  end
  colid = @collection.noid unless colid

  collection = DRI::Identifier.retrieve_object(colid)
  object.governing_collection = collection
  checksum_metadata(object)
  object.update_index
  object.save
  collection.save
end

Given /^the collection(?: with pid "(.*?)")? is published?$/ do |colid|
  colid = @collection.noid unless colid

  collection = DRI::Identifier.retrieve_object(colid)
  collection.governed_items.each do |o|
    o.status = 'published'
    o.save
  end
  collection.status = 'published'
  collection.save
end

Given /^I have associated the institute "(.?*)" with the collection with pid "(.?*)"$/ do |institute_name,pid|
  if pid == 'the saved pid'
    pid = @collection_pid || @pid
  end

  collection = DRI::Identifier.retrieve_object(pid)

  institute = Institute.new
  institute.name = institute_name
  institute.url = "http://www.dri.ie"

  logo = Rack::Test::UploadedFile.new(File.join(cc_fixture_path, "sample_logo.png"), "image/png")
  institute.store_logo(logo, institute_name)
  institute.save

  collection.institute = collection.institute.push(institute.name)
  collection.depositing_institute = institute.name
  collection.save
end

When /^I create a Digital Object in the collection "(.*?)"$/ do |collection_pid|
  steps %{
    When I go to the "collection" "show" page for "#{collection_pid}"
    And I follow the link to upload XML
    And I attach the metadata file "valid_metadata.xml"
    And I press the button to "ingest metadata"
  }
end

When /^I enter valid metadata for a collection(?: with title (.*?))?$/ do |title|
    title ||= "Test collection"
  steps %{
    When I fill in "digital_object_title][" with "#{title}"
    And I fill in "digital_object_description][" with "Test description"
    And I fill in "digital_object_rights][" with "Test rights"
    And I fill in "digital_object_creator][" with "test@test.com"
    And I fill in "digital_object_creation_date][" with "2000-01-01"
  }
end

When /^I enter invalid metadata for a collection(?: with title (.*?))?$/ do |title|
    title ||= "Test collection"
  steps %{
    When I fill in "digital_object_title][" with "#{title}"
    And I fill in "digital_object_description][" with "Test description"
    And I fill in "digital_object_creation_date][" with "2000-01-01"
    And I fill in "digital_object_rights][" with ""
    And I fill in "digital_object_type][" with "Collection"
  }
end

When /^I enter valid permissions for a collection$/ do
  steps %{
    When choose "digital_object_read_groups_string_radio_public"
  }
end

When /^I enter invalid permissions for a collection$/ do
  steps %{
    And I fill in "digital_object_manager_users_string" with ""
    And I fill in "digital_object_edit_users_string" with ""
  }
end

When /^I add the Digital Object "(.*?)" to the collection "(.*?)" as type "(.*?)"$/ do |object_pid,collection_pid,type|
  object = DRI::Identifier.retrieve_object(object_pid)
  collection = DRI::Identifier.retrieve_object(collection_pid)
  case type
    when "governing"
      object.title = [SecureRandom.hex(5)]
      object.governing_collection = collection
      object.save
  end
end

When /^I press the remove from collection button for Digital Object "(.*?)"/ do |object_pid|
   click_link_or_button(button_to_id("remove from collection #{object_pid}"))
end

Then /^the collection "(.*?)" should contain the Digital Object "(.*?)"(?: as type "(.*?)")?$/ do |collection_pid,object_pid,*type|
  object = DRI::Identifier.retrieve_object(object_pid)
  collection = DRI::Identifier.retrieve_object(collection_pid)
  case type
    when "governing"
      collection.governed_items.length.should == 1
      collection.governed_items[0].title.should == object.title
  end
end

Then /^I should get a duplicate object warning$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I press the button to set the current collection to "(.*?)"/ do |collection_pid|
   click_link_or_button(button_to_id("set current collection #{collection_pid}"))
end

Then /^I should be given a choice of using the existing object or creating a new one$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see the Digital Object "(.*?)" as part of the collection$/ do |object_pid|
  object = DRI::Identifier.retrieve_object(object_pid)
  page.should have_content object.title
end

Then /^the collection "(.*?)" should contain the new digital object$/ do |collection_pid|
  collection = DRI::Identifier.retrieve_object(collection_pid)
  collection.governed_items.count.should == 1
  collection.governed_items[0].title.should == ["SAMPLE AUDIO TITLE"]
end

When /^I check add to collection for id (.*?)$/ do |object_pid|
  click_link_or_button(button_to_id("add to collection for id #{object_pid}"))
end
