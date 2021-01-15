include DRI::Duplicable

module CollectionHelper
  # @param [String] pid
  # @return [FedoraObject] collection
  def get_collection(pid = nil)
    # override pid with collection id if pid is nil and collection.id exists
    pid ||= @collection&.noid
    if pid == 'the saved pid'
      pid = @collection_pid ? @collection_pid : @pid
    end
    DRI::DigitalObject.find_by_noid(pid)
  end
end
World(CollectionHelper)

Given /^a collection with(?: pid "(.*?)")?(?: (?:and )?title "(.*?)")?(?: created by "(.*?)")?$/ do |pid, title, user|
  pid = @random_pid if (pid.nil? || pid == "random")
  @pid = pid

  @collection = DRI::QualifiedDublinCore.new(noid: pid)
  @collection.title = title ? [title] : [SecureRandom.hex(5)]
  @collection.description = [SecureRandom.hex(20)]
  @collection.rights = [SecureRandom.hex(20)]
  @collection.type = ["Collection"]
  @collection.creation_date = ["2000-01-01"]
  user ||= 'test'
  if user
    email = "#{user}@#{user}.com"
    User.create(
      email: email,
      password: "password",
      password_confirmation: "password",
      locale: "en",
      first_name: "fname",
      second_name: "sname",
      image_link: File.join(cc_fixture_path, 'sample_image.png')
    ) if User.find_by_email(email).nil?

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

  group = UserGroup::Group.new(name: @collection.noid,
                               description: "Default Reader group for collection #{@collection.noid}")
  group.save
end

Given /^a published collection with pid "([^\"]+)" and (\d+) images$/ do |pid, num_images|
  total_steps = %{
    Given a collection with pid "#{pid}" created by "admin"
  }
  num_images.times do |i|
    total_steps += %{
      And a Digital Object with pid "object#{i}" in collection "#{pid}"
      And I add the asset "sample_image.tiff" to "object#{i}"
    }
  end

  total_steps += %{
    And published_images returns generic files from "#{pid}"
    And I have associated the institute "TestInstitute" with the collection with pid "#{pid}"
    And the collection with pid "#{pid}" is published
  }

  steps total_steps
end

Given /^a Digital Object(?: with)?(?: pid "(.*?)")?(?:(?: and)? title "(.*?)")?(?:, description "(.*?)")?(?:, type "(.*?)")?(?: created by "(.*?)")?(?: in collection "(.*?)")?/ do |pid, title, desc, type, user, coll|
  pid = @random_pid if (pid == "random")
  if pid
    @digital_object = DRI::QualifiedDublinCore.create(noid: pid)
    # TODO: add similar guard clause to build_hash_dir ?
    err_msg = 'A pid must be at least 6 characters long. '\
    'Otherwise methods will break, for example '\
    'preservation_helpers.rb#build_hash_dir assumes pid.length >= 6'
    raise ArgumentError, err_msg if pid.length < 6
    @digital_object = DRI::DigitalObject.with_standard(:qdc, { noid: pid })
  else
    @digital_object = DRI::DigitalObject.with_standard(:qdc)
  end

  @digital_object.title = title ? [title] : ["Test Object"]
  @digital_object.type = type ? [type] : ["Sound"]
  @digital_object.description = desc ? [desc] : ["A test object"]

  user ||= 'test'
  email = "#{user}@#{user}.com"
  @obj_user = User.find_by_email(email)
  @obj_user ||= User.create(email: email, password: "password", password_confirmation: "password",
                          locale: "en", first_name: "fname", second_name: "sname",
                          image_link: File.join(cc_fixture_path, 'sample_image.png'))
  obj_user_str = @obj_user.to_s

  @digital_object.depositor = obj_user_str
  @digital_object.manager_users_string = obj_user_str
  @digital_object.creator = [email]
  @digital_object.rights = ["This is a statement of rights"]
  @digital_object.creation_date = ["2000-01-01"]
  @digital_object.status = 'draft'

  coll ||= @collection.noid unless @collection.nil?

  @digital_object.governing_collection = DRI::Identifier.retrieve_object(coll) if coll

  checksum_metadata(@digital_object)
  @digital_object.save!

  preservation = Preservation::Preservator.new(@digital_object)
  preservation.preserve(['descMetadata'])
end

Given /^the collection with pid "([^\"]+)" is in the collection with pid "([^\"]+)"$/ do |subcolid, colid|
  subcollection = DRI::DigitalObject.find_by_noid(subcolid)
  subcollection.governing_collection = DRI::DigitalObject.find_by_noid(colid)
  subcollection.save
end

Given /^the object(?: with pid "(.*?)")? is in the collection(?: with pid "(.*?)")?$/ do |objid, colid|
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
  collection = get_collection(colid)
  collection.governed_items.each do |o|
    o.status = 'published'
    o.read_groups_string = 'public'
    o.save
  end
  collection.read_groups_string = 'public'
  collection.status = 'published'
  collection.save
end

Given /^the collection(?: with pid "(.*?)")? has "([^\"]+)" = "([^\"]+)"$/ do |colid, field, value|
  collection = get_collection(colid)
  value = [value] if collection.attributes[field].is_a?(Array)

  collection.send("#{field}=", value)
  collection.save
end

Given /^I have associated the institute "([^\"]+)" with the collection with pid "([^\"]+)"$/ do |institute_name, pid|
  collection = get_collection(pid)
  institute = Institute.new(name: institute_name, url: "http://www.dri.ie")

  logo = Rack::Test::UploadedFile.new(File.join(cc_fixture_path, "sample_logo.png"), "image/png")
  institute.store_logo(logo, institute_name)
  institute.save

  collection.institute = collection.institute.push(institute_name)
  collection.depositing_institute = institute_name
  collection.save
end

# Given /^the object with pid "([^\"]+) is reviewed"$/ do |pid|
Given /^the (object|collection)(?: with pid "([^\"]+)")? is reviewed$/ do |_, objid|
  if objid
    object = DRI::DigitalObject.find_by_noid(objid)
  else
    object = @digital_object
  end
  object.status = 'reviewed'
  object.save
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

When /^I (click|press) the edit collection button with text "(.*?)"$/ do |_, button_text|
  # span does not exist when translation is present
  find('fieldset a', text: button_text).click
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
