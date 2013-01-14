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
  attach_file("metadata_file", "spec/fixtures/#{file}")
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

Then /^show me the page$/ do
  save_and_open_page
end

Then /^I should see the error "([^\"]*)"$/ do |error|
  page.should have_content error
end 

Then /^I should see the message "([^\"]*)"$/ do |message| 
  page.should have_selector ".alert", text: message
end

def path_to(page_name)
    
    case page_name
  
    when /new Digital Object page/
      new_audio_path 

    when /show Digital Object page for id (.+)/
      catalog_path($1)

    when /edit Digital Object page for id (.+)/
      edit_audio_path($1)      

    when /the home page/
      '/'

    when /User Signin page/
      '/users/sign_in'

    when /User Sign up page/
      '/users/sign_up'

    end
end

