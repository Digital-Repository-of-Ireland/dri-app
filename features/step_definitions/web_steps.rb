module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Given /^I have created a Digital Object$/ do
  steps %{
    Given I am on the new Digital Object page
    When I attach the metadata file "valid_metadata.xml"
    And I press "Ingest Metadata"
  }
end

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )follow "([^"]*)"(?: within "([^"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^I attach the metadata file "(.*?)"$/ do |file|
  attach_file("metadata_file", File.join(cc_fixture_path, file))
end

When /^I attach the audio file "(.*?)"$/ do |file|
  attach_file("Filedata", File.join(cc_fixture_path, file))
end

Then /^I press "(.*?)"$/ do |button|
  click_button(button)
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

Then /^I should see a link to "([^\"]*)"$/ do |text|
  page.should have_link(text)
end

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
