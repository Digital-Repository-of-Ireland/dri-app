Given /^a collection with pid "(.*?)"(?: and title "(.*?)")?(?: created by "(.*?)")?$/ do |pid, title, user|
  pid = "dri:c" + @random_pid if (pid == "@random")
  collection = Batch.new(:pid => pid)
  collection.title = title ? title : SecureRandom.hex(5)
  collection.description = SecureRandom.hex(20)
  collection.rights = SecureRandom.hex(20)
  collection.type = ["Collection"]
  collection.date = ["2000-01-01"]
  if user
    User.create(:email => user, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png')) if User.find_by_email(user).nil?

    collection.depositor = User.find_by_email(user).to_s
    collection.manager_users_string=User.find_by_email(user).to_s
  end
  collection.save
  collection.items.count.should == 0
  collection.governed_items.count.should == 0

  group = UserGroup::Group.new(:name => collection.id.sub(':', '_'),
                              :description => "Default Reader group for collection #{collection.id}")
  group.save
end


Given /^a Digital Object with pid "(.*?)"(?:, title "(.*?)")?(?:, description "(.*?)")?(?:, type "(.*?)")?(?: created by "(.*?)")?/ do |pid, title, desc, type, user|
  pid = "dri:o" + @random_pid if (pid == "@random")
  digital_object = Batch.new(:pid => pid)
  digital_object.title = title ? [title] : "Test Object"
  digital_object.type = type ? [type] : "Sound"
  digital_object.object_type = type ? [type] : "Sound"
  digital_object.description = desc ? [desc] : "A test object"
  if user
    User.create(:email => user, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png')) if User.find_by_email(user).nil?

    digital_object.depositor=User.find_by_email(user).to_s
    digital_object.manager_users_string=User.find_by_email(user).to_s
    digital_object.edit_groups_string="registered"
  end
  digital_object.rights = ["This is a statement of rights"]
  digital_object.date = ["2000-01-01"]
  digital_object.save
end

Given /^a Digital Object of type "(.*?)" with pid "(.*?)" and title "(.*?)"(?: created by "(.*?)")?/ do |type, pid, title, user|
  pid = "dri:o" + @random_pid if (pid == "@random")
  case type
   when 'Audio'
    digital_object = DRI::Model::Audio.new(:pid => pid)
   when 'Pdf'
    digital_object = DRI::Model::Pdfdoc.new(:pid => pid)
  end

  digital_object.title = title
  if user
    digital_object.depositor = User.find_by_email(user).to_s
    digital_object.manager_users_string=User.find_by_email(user).to_s
    digital_object.edit_groups_string="registered"
  end
  digital_object.date = ["2000-01-01"]
  digital_object.rights = ["This is a statement of rights"]
  digital_object.save
end

Given /^the object with pid "(.*?)" is in the collection with pid "(.*?)"$/ do |objid,colid|
  object = ActiveFedora::Base.find(objid, {:cast => true})
  collection = ActiveFedora::Base.find(colid, {:cast => true})
  collection.governed_items << object
  collection.save
  object.save
end

Given /^I have associated the institute "(.?*)" with the colleciton entitled "(.?*)"$/ do |institute,collection|
  steps %{
    Given I am on the home page
    When I perform a search
    And I press "#{collection}"
    And I follow the link to edit a collection
    And I fill in "institute[name]" with "#{institute}"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to add an institute
    And I wait for the ajax request to finish
    Then the "institute" drop-down should contain the option "#{institute}"
    When I select "#{institute}" from the selectbox for institute
    And I press the button to associate an institute
    And I wait for the ajax request to finish
    Then I should see the image "#{institute}.png"
  }
end

When /^I create a Digital Object in the collection "(.*?)"$/ do |collection_pid|
  steps %{
    Given I am on the new Digital Object page
    And I select "#{collection_pid}" from the selectbox for ingest collection
    And I press the button to continue
    And I select "Text" from the selectbox for object type
    And I press the button to continue
    And I select "upload" from the selectbox for ingest methods
    And I press the button to continue
    And I attach the metadata file "valid_metadata.xml"
    And I press the button to ingest metadata
  }
end

When /^I add the Digital Object "(.*?)" to the non-governing collection "(.*?)" using the web forms$/ do |object_pid,collection_pid|
  steps %{
    Given I am on the collections page
    When I press the button to set the current collection to #{collection_pid}
    And I go to the "object" "show" page for "#{object_pid}"
    And I check add to collection for id #{object_pid}
  }
end

When /^I enter valid metadata for a collection(?: with title (.*?))?$/ do |title|
    title ||= "Test collection"
  steps %{
    When I fill in "batch_title][" with "#{title}"
    And I fill in "batch_description][" with "Test description"
    And I fill in "batch_rights][" with "Test rights"
    And I fill in "batch_type][" with "Collection"
    And I fill in "batch_creation_date][" with "2000-01-01"
    And I select "publisher" from the selectbox number 0 for role type
    And I fill in "batch_roles][name][" number 0 with "Test publisher"
  }
  #{}  And I select "publisher" from the selectbox number 0 for role type
  #{}  And I fill in "batch_roles][name][" number 0 with "Test publisher"
  #{}}
end

When /^I enter valid permissions for a collection$/ do
  steps %{
    When choose "batch_read_groups_string_radio_public"
  }
end

When /^I enter invalid permissions for a collection$/ do
  steps %{
    And I fill in "batch_manager_users_string" with ""
  }
end

When /^I add the Digital Object "(.*?)" to the collection "(.*?)" as type "(.*?)"$/ do |object_pid,collection_pid,type|
  object = ActiveFedora::Base.find(object_pid, {:cast => true})
  collection = ActiveFedora::Base.find(collection_pid, {:cast => true})
  case type
    when "governing"
      object.title = SecureRandom.hex(5)
      collection.governed_items << object
    when "non-governing"
      object.title = SecureRandom.hex(5)
      collection.items << object
  end
end

When /^I press the remove from collection button for Digital Object "(.*?)"/ do |object_pid|
   click_link_or_button(button_to_id("remove from collection #{object_pid}"))
end

Then /^the collection "(.*?)" should contain the Digital Object "(.*?)"(?: as type "(.*?)")?$/ do |collection_pid,object_pid,*type|
  object = ActiveFedora::Base.find(object_pid, {:cast => true})
  collection = ActiveFedora::Base.find(collection_pid, {:cast => true})
  case type
    when "governing"
      collection.governed_items.length.should == 1
      collection.governed_items[0].title.should == object.title
    when "non-governing"
      collection.items.length.should == 1
      collection.items[0].title.should == object.title
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
  object = Batchfind(object_pid)
  page.should have_content object.title
end

Then /^I should not see the Digital Object "(.*?)" as part of the non-governing collection$/ do |object_pid|
  object = Batch.find(object_pid)
  page.should_not have_content object.title
end

Then /^the collection "(.*?)" should contain the new digital object$/ do |collection_pid|
  collection = ActiveFedora::Base.find(collection_pid, {:cast => true})
  collection.governed_items.count.should == 1
  collection.governed_items[0].title.should == ["SAMPLE AUDIO TITLE"]
end

When /^I check add to collection for id (.*?)$/ do |object_pid|
  click_link_or_button(button_to_id("add to collection for id #{object_pid}"))
end
