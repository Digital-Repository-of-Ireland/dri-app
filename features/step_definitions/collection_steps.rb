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

When /^I add the Digital Object to a collection$/ do
  pending # express the regexp above with the code you wish you had
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

When /^I add the Digital Object to the collection$/ do
  @digital_object.title = "Test digital object 1"
  @collection.governed_items << @digital_object
end

Then /^the collection should exist$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^the collection should contain the Digital Object$/ do
  @collection.governed_items.length.should == 1
  @collection.governed_items[0].title.should == "Test digital object 1"
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

Given /^the collection already contains the Digital Object$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I retrieve the collection$/ do
  pending # express the regexp above with the code you wish you had
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
