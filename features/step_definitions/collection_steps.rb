Given /^a collection that does not exist$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I create a Digital Object in the existing collection$/ do
  steps %{
    Given I am on the new Digital Object page
    And I select "#{@collection.pid}" from the selectbox for ingest collection
    And I press the button to continue
    And I select "audio" from the selectbox for object type
    And I press the button to continue
    And I select "upload" from the selectbox for ingest methods
    And I press the button to continue
    And I attach the metadata file "valid_metadata.xml"
    And I press the button to ingest metadata
  }
end

When /^I add the Digital Object to the non-governing collection using the web forms$/ do
  steps %{
    Given I am on the edit Digital Object page for id #{@digital_object.pid}
    And I select "#{@collection.pid}" from the selectbox for add to collection
    And I press the button to add to collection
  }
end

When /^I enter valid metadata for a collection$/ do
  steps %{
    When I fill in "dri_model_collection_title" with "Test collection"
    And I fill in "dri_model_collection_description" with "Test description"
    And I fill in "dri_model_collection_publisher" with "Test publisher"
  }
end

When /^I enter valid metadata for a collection with title (.*?)$/ do |title|
  steps %{
    When I fill in "dri_model_collection_title" with "#{title}"
    And I fill in "dri_model_collection_description" with "Test description"
    And I fill in "dri_model_collection_publisher" with "Test publisher"
  }
end

When /^I add the Digital Object to the governing collection$/ do
  @digital_object.title = SecureRandom.hex(5)
  @collection.governed_items << @digital_object
end

When /^I add the Digital Object to the non-governing collection$/ do
  @digital_object.title = SecureRandom.hex(5)
  @collection.items << @digital_object
end

Then /^the collection should exist$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^the governing collection should contain the Digital Object$/ do
  @collection.governed_items.length.should == 1
  @collection.governed_items[0].title.should == @digital_object.title
end

Then /^the non-governing collection should contain the Digital Object$/ do
  @collection.items.length.should == 1
  @collection.items[0].title.should == @digital_object.title
end

Then /^I should get a duplicate object warning$/ do
  pending # express the regexp above with the code you wish you had
end

Given /^an existing collection$/ do
  @collection = DRI::Model::Collection.new
  @collection.title = @collection.pid
  @collection.description = @collection.pid
  @collection.publisher = @collection.pid
  @collection.save
end

Given /^an existing Digital Object/ do
  @digital_object = FactoryGirl.build(:audio)
  @digital_object.save
end

Given /^the collection already contains the Digital Object$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I retrieve the collection$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I press the remove from collection button/ do
   click_link_or_button(button_to_id("remove from collection #{@digital_object.pid}"))
end

Then /^I should see my Digital Objects$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should be given a choice of using the existing object or creating a new one$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see my collections$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see the Digital Object as part of the collection$/ do
  page.should have_content @collection.governed_items[0].title
end

Then /^I should see the Digital Object as part of the non-governing collection$/ do
  page.should have_content @digital_object.title
end

Then /^I should not see the Digital Object as part of the non-governing collection$/ do
  page.should_not have_content @digital_object.title
end
