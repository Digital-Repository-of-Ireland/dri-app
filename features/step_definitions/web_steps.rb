module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Given /^I have created a Digital Object$/ do
  steps %{
    Given I have created a collection
    And I am on the new Digital Object page
    And I select a collection
    And I press the button to continue
    And I select "audio" from the selectbox for object type
    And I press the button to continue
    And I select "upload" from the selectbox for ingest methods
    And I press the button to continue
    And I attach the metadata file "valid_metadata.xml"
    And I press the button to ingest metadata
  }
end

Given /^I have created a (pdfdoc|audio) object$/ do |type|
  steps %{
    Given I have created a collection
    And I am on the new Digital Object page
    And I select a collection
    And I press the button to continue
    And I select "#{type}" from the selectbox for object type
    And I press the button to continue
    And I select "upload" from the selectbox for ingest methods
    And I press the button to continue
    And I attach the metadata file "valid_metadata.xml"
    And I press the button to ingest metadata
  }
end

Given /^I have created an "(.*?)" object with metadata "(.*?)" in the collection "(.*?)"$/ do |type, metadata, collection_title|
  steps %{
    Given I am on the new Digital Object page
    When I select the text "#{collection_title}" from the selectbox for ingest collection
    And I press the button to continue
    And I select "#{type}" from the selectbox for object type
    And I press the button to continue
    And I select "upload" from the selectbox for ingest methods
    And I press the button to continue
    And I attach the metadata file "#{metadata}"
    And I press the button to ingest metadata
  }
end

Given /^I have created an "(.*?)" object with title "(.*?)" in the collection "(.*?)"$/ do |type, title, collection_title|
  steps %{
    Given I am on the new Digital Object page
    When I select the text "#{collection_title}" from the selectbox for ingest collection
    And I press the button to continue
    And I select "#{type}" from the selectbox for object type
    And I press the button to continue
    And I select "input" from the selectbox for ingest methods
    And I press the button to continue
    When I enter valid metadata with title "#{title}"
    And I press the button to continue
  }
end
 
Given /^I have created a collection$/ do
  steps %{
    Given I am on the my collections page
    And I press the button to add new collection
    And I enter valid metadata for a collection
    And I press the button to create a collection
  }
end

Given /^I have created a collection with title "(.+)"$/ do |title|
  steps %{
    Given I am on the my collections page
    And I press the button to add new collection
    And I enter valid metadata for a collection with title #{title}
    And I press the button to create a collection
  }
end

Given /^I have added an audio file$/ do
  steps %{
    Then I should see a link to edit an object
    When I follow the link to edit an object
    And I attach the asset file "sample_audio.mp3"
    And I press the button to upload a file
    Then I should see a success message for file upload
  }
end

When /^I add the asset "(.*)" to "(.*?)"$/ do |asset, pid|
  steps %{
    When I go to the "object" "edit" page for "#{pid}"
    And I attach the asset file "#{asset}"
    And I press the button to upload a file
    Then I should see a success message for file upload
  }
end

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to "([^"]*)"$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to the "([^"]*)" "([^"]*)" page for "([^"]*)"$/ do |type, page, pid|
  visit path_for(type, page, pid)
end

When /^(?:|I )follow the link to (.+)$/ do |link_name|
  click_link(link_to_id(link_name))
end

When /^(?:|I )follow "([^"]*)"(?: within "([^"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^I select "(.*?)" from the selectbox for (.*?)$/ do |option, selector|
  select_by_value(option, :from => select_box_to_id(selector))
end

When /^I select the text "(.*?)" from the selectbox for (.*?)$/ do |option, selector|
  select(option, :from => select_box_to_id(selector))
end

When /^I attach the metadata file "(.*?)"$/ do |file|
  attach_file("metadata_file", File.join(cc_fixture_path, file))
end

When /^I enter valid metadata(?: with title "(.*?)")?$/ do |title|
  title ||= "A Test Object"
  interface.enter_valid_metadata(title)
end

When /^I enter modified metadata$/ do
  interface.enter_modified_metadata
end

When /^I attach the asset file "(.*?)"$/ do |file|
  attach_file("Filedata", File.join(cc_fixture_path, file))
end

When /^I select a collection$/ do
  second_option_xpath = "//*[@id='ingestcollection']/option[2]"
  second_option = find(:xpath, second_option_xpath).value
  select_by_value(second_option, :from => "ingestcollection")
end

Then /^I should see the (valid|modified) metadata$/ do |type|
  case type
    when "valid"
      interface.has_valid_metadata?
    when "modified"
      interface.has_modified_metadata?
  end
end

Then /^I press "(.*?)"$/ do |button|
  click_link_or_button(button)
end

Then /^(?:|I )press the button to (.+)$/ do |button|
  click_link_or_button(button_to_id(button))
end 

Then /^(?:|I )should see a link to (.+)$/ do |link|
  page.should have_link(link_to_id(link))
end

Then /^(?:|I )should not see a link to (.+)$/ do |link|
  page.should_not have_link(link_to_id(link))
end

Then /^(?:|I )should see a "([^"]*)"$/ do |element|
  case element
    when "rights statement"
      interface.has_rights_statement?
    when "licence"
      interface.has_licence?
  end
end

Then /^(?:|I )should see a (success|failure) message for (.+)$/ do |sucess_failure,message|
  page.should have_selector ".alert", text: flash_for(message)
end

Then /^(?:|I )should see a message for (.+)$/ do |message|
  page.should have_selector ".alert", text: flash_for(message)
end

Then /^(?:|I )should not see a message for (.+)$/ do |message|
  page.should_not have_selector ".alert", text: flash_for(message)
end

Then /^(?:|I )should see "([^"]*)"(?: within "([^"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if page.respond_to? :should
      page.should have_content(text)
    else
      assert page.has_content?(text)
    end
  end
end

Then /^the object should be (.*?) format$/ do |format|
  interface.is_format?(format)
end

#Then /^I should see a link to "([^\"]*)"$/ do |text|
#  page.should have_link(text)
#end

Then /^I should see a link to "([^\"]*)" with text "([^\"]*)"$/ do |url, text|
  page.should have_link(text, href: url) 
end

Then /^I should not see a link to "([^\"]*)"$/ do |text|
  page.should_not have_link(text)
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  if current_path.respond_to? :should
    current_path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), current_path
  end
end

When /^(?:|I )fill in "([^"]*)" with "([^"]*)"(?: within "([^"]*)")?$/ do |field, value, selector|
  with_scope(selector) do
    fill_in(field, :with => value)
  end
end

Then /^the "([^"]*)" field(?: within "([^"]*)")? should contain "([^"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should
      field_value.should =~ /#{value}/
    else
      assert_match(/#{value}/, field_value)
    end
  end
end

Then /^the "([^"]*)" field(?: within "([^"]*)")? should not contain "([^"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should_not
      field_value.should_not =~ /#{value}/
    else
      assert_no_match(/#{value}/, field_value)
    end
  end
end

Then /^show me the page$/ do
  save_and_open_page
end

Then /^I should see the error "([^\"]*)"$/ do |error|
  page.should have_content error
end 

Then /^I should see the message "([^\"]*)"$/ do |message| 
  page.should have_selector ".alert", text: message
end

Then /^I should not see the message "([^\"]*)"$/ do |message|
  page.should_not have_selector ".alert", text: message
end

Then /^I should (not )?see an element "([^"]*)"$/ do |negate, selector|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_css(selector))
end
