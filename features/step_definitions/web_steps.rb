module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Given /^"(.*?)" has created a Digital Object$/ do |user|
  col_pid = "#{rand.to_s[2..11]}"
  @obj_pid = "#{rand.to_s[2..11]}"
  steps %{
    Given a collection with pid "#{col_pid}" created by "#{user}"
    And a Digital Object with pid "#{@obj_pid}", title "Object 1" created by "#{user}"
    And the object with pid "#{@obj_pid}" is in the collection with pid "#{col_pid}"
    When I go to the "object" "show" page for "#{@obj_pid}"
    And I click the link to edit
    And I attach the metadata file "valid_metadata.xml"
    And I press the button to "upload metadata"
    Then I should see a success message for updating metadata
  }
end

Given /^I have created an object with metadata "(.*?)" in the collection with pid "(.*?)"$/ do |metadata_file, collection_pid|
  steps %{
    When I go to the "metadata" "upload" page for "#{collection_pid}"
    And I attach the metadata file "#{metadata_file}"
    And I press the button to "ingest metadata"
    Then I should see a success message for ingestion
  }
end

Given /^I have created an object with title "(.*?)" in the collection with pid "(.*?)"$/ do |title, collection_pid|
  steps %{
    When I go to the "collection" "show" page for "#{collection_pid}"
    And I follow the link to add an object
    When I enter valid metadata with title "#{title}"
    And I press the button to "continue"
  }
end

Given /^I have created a collection$/ do
  steps %{
    Given I am on the home page
    And I go to "create new collection"
    And I enter valid metadata for a collection
    And I check "deposit"
    And I press the button to "create a collection"
  }
end

Given /^I have created a collection with title "(.+)"$/ do |title|
  steps %{
    Given I am on the home page
    When I go to "create new collection"
    And I enter valid metadata for a collection with title #{title}
    And I check "deposit"
    And I press the button to "create a collection"
  }
end

Given /^I have added an audio file$/ do
  steps %{
    Then I should see a link to edit an object
    When I follow the link to edit an object
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "upload a file"
    Then I should see a success message for file upload
  }
end

Given /^I have created an institute "(.+)"$/ do |institute|
  steps %{
    Given I am on the new organisation page
    When I fill in "institute[name]" with "#{institute}"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
  }
end

When /^I add the asset "(.*)" to "(.*?)"$/ do |asset, pid|
  steps %{
    When I go to the "object" "show" page for "#{pid}"
    And I attach the asset file "#{asset}"
    And I press the button to "upload a file"
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
  if (pid.eql?('the saved pid') && type.eql?("collection"))
    pid = @collection_pid ? @collection_pid : @pid
  elsif (pid.eql?('the saved pid') && type.eql?("object"))
    pid = @pid if pid.eql?('the saved pid')
  end
  visit path_for(type, page, pid)
end

When /^(?:|I )follow the link to (.+)$/ do |link_name|
  if Capybara.current_driver == Capybara.javascript_driver
    page.find_link(link_to_id(link_name)).trigger('click')
  else
    page.find_link(link_to_id(link_name)).click
  end
end

# Use this step when overlaping elements might confuse Capybara
# - it ignores overlaping <a> elements and just fires the click
# event on the selected element.
When /^(?:|I )click the link to (.+)$/ do |link_name|
  element = page.find(:id, link_to_id(link_name))
  element.trigger('click')
end

When /^(?:|I )follow "([^"]*)"(?: within "([^"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^I select "(.*?)" from the selectbox for (.*?)$/ do |option, selector|
  select_by_value(option, :from => select_box_to_id(selector))
end

When /^I select "(.*?)" from the selectbox number (.*?) for (.*?)$/ do |option, index, selector|
  page.all(:xpath, '//select[@id="'+select_box_to_id(selector)+'"]')[index.to_i].find(:xpath, ".//option[@value='#{option}']").select_option
  #select_by_value(option, :xpath => selected_select)
end

When /^I select the text "(.*?)" from the selectbox for (.*?)$/ do |option, selector|
  select(option, :from => select_box_to_id(selector))
end

When /^I upload the metadata file "(.*?)"$/ do |file|
    attach_file("dri_metadata_uploader", File.expand_path(File.join(cc_fixture_path, file)))
end

When /^I attach the metadata file "(.*?)"$/ do |file|
  #within(:xpath, "//div[contains(concat(' ', @class, ' '), 'dri_file_upload')]") do
  within('#metadata_uploader') do
    attach_file("metadata_file", File.expand_path(File.join(cc_fixture_path, file)))
  end
end

When /^I attach the institute logo file "(.*?)"$/ do |file|
  attach_file("institute[logo]", File.join(cc_fixture_path, file))
end

When /^I attach the cover image file "(.*?)"$/ do |file|
  attach_file("batch_cover_image", File.expand_path(File.join(cc_fixture_path, file)))
end

When /^I enter valid metadata(?: with title "(.*?)")?$/ do |title|
  title ||= "A Test Object"
  interface.enter_valid_metadata(title)
end

When /^I enter invalid metadata(?: with title "(.*?)")?$/ do |title|
  title ||= "A Test Object"
  interface.enter_invalid_metadata(title)
end

When /^I enter valid "(sound|text)" metadata$/ do |type|
  title ||= "A Test Object"
  case type
    when "sound"
      interface.enter_valid_metadata(title)
    when "text"
      interface.enter_valid_pdf_metadata(title)
  end
end

When /^I enter modified metadata$/ do
  interface.enter_modified_metadata
end

When /^I enter valid licence information for licence "(.*?)" into the new licence form$/ do |name|
  interface.enter_valid_licence(name)
end

When /^I enter an url to a licence logo$/ do
  fill_in("licence[logo]", :with => "http://i.creativecommons.org/l/by/4.0/88x31.png")
end

When /^I attach the licence logo file "(.*?)"$/ do |file|
  attach_file("logo_file", File.join(cc_fixture_path, file))
end

Given /^I have created a licence "(.*?)"$/ do |name|
  licence = Licence.create(:name=>name, :description=>'This is a description', :url=>"http://www.dri.ie/", :logo=>"http://creativecommons.org/licenses/by/4.0/deed.en_US")
end

When /^I attach the asset file "(.*?)"$/ do |file|
  attach_file("Filedata", File.join(cc_fixture_path, file))
end

When /^I select a collection$/ do
  second_option_xpath = "//*[@id='ingestcollection']/option[2]"
  second_option = find(:xpath, second_option_xpath).value
  select_by_value(second_option, :from => "ingestcollection")
end

When /^I select the "(objects|collections)" tab$/ do |tab|
  case tab
    when "objects"
      click_link("objects")
    when "collections"
      click_link("collections")
  end
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
  Capybara.ignore_hidden_elements = false
  click_link_or_button(button)
end

Then /^(?:|I )press the modal button to "(.*?)" in "(.*?)"$/ do |button,modal|
  page.find_by_id(modal, :visible=>false).find_by_id(button_to_id(button)).trigger('click')
end

Then /^(?:|I )press the button to "([^"]*)"(?: within "([^"]*)")?$/ do |button,selector|
  Capybara.ignore_hidden_elements = false
  if selector
    within("//*[@id='#{selector}']") do
      page.find_button(button_to_id(button)).click
    end
  else
    page.find_button(button_to_id(button), {visible: false}).click
  end
end

Then /^I check "(.*?)"$/ do |checkbox|
  Capybara.ignore_hidden_elements = false
  page.find_by_id(checkbox, { visible: false}).trigger('click')
end

When /^(?:|I )perform a search$/ do
  # Requires javascript
  find(:id, 'q').native.send_keys(:enter)
end

Then /^(?:|I )should( not)? see a button to (.+)$/ do |negate,button|
   negate ? (page.should_not have_button(button_to_id(button))) : (page.should have_button(button_to_id(button)))
end

Then /^(?:|I )should( not)? see a link to (.+)$/ do |negate,link|
  negate ? (page.should_not have_link(link_to_id(link))) : (page.should have_link(link_to_id(link)))
end

Then /^(?:|I )should see a "([^"]*)"$/ do |element|
  case element
    when "rights statement"
      interface.has_rights_statement?
    when "licence"
      interface.has_licence?
  end
end

Then /^(?:|I )should see a selectbox for "(.*?)"$/ do |id|
  page.should have_select id
end

Then /^(?:|I )should( not)? see a (success|failure) message for (.+)$/ do |negate, success_failure, message|
  url = current_url
  @obj_pid = URI(url).path.split('/').last
  begin
    negate ? (page.should_not have_selector ".dri_messages_container", text: flash_for(message)): (page.should have_selector ".dri_messages_container", text: flash_for(message))
  rescue
    #save_and_open_page
    raise
  end
end

Then /^(?:|I )should( not)? see a message for (.+)$/ do |negate, message|
  negate ? (page.should_not have_selector ".dri_messages_container", text: flash_for(message)) : (page.should have_selector ".dri_messages_container", text: flash_for(message))
end

Then /^(?:|I )should( not)? see a window about cookies$/ do |negate|
  negate ? (page.should_not have_selector ".modal-title", text: flash_for("cookie terms")) : (page.should have_selector ".modal-title", text: flash_for("cookie terms"))
end

Then /^(?:|I )should( not)? see a message about cookies$/ do |negate|
  negate ? (page.should_not have_selector ".alert", text: flash_for("cookie notification")) : (page.should have_selector ".alert", text: flash_for("cookie notification"))
end

Then /^(?:|I )should( not)? see "([^"]*)"(?: within "([^"]*)")?$/ do |negate, text, selector|
  with_scope(selector) do
    if !negate.nil? && !negate.blank?
      if page.respond_to? :should_not
        page.should_not have_content(text)
      else
        assert !page.has_content?(text)
      end
    else
      if page.respond_to? :should
        page.should have_content(text)
      else
        assert page.has_content?(text)
      end
    end
  end
end

Then /^the object should be (.*?) format$/ do |format|
  interface.is_format?(format)
end

Then /^the object should be of type (.*?)$/ do |type|
  interface.is_type?(type)
end

Then /^I should see a link to "([^\"]*)" with text "([^\"]*)"$/ do |url, text|
  page.should have_link(text, href: url)
end

Then /^I should see a form for (.+)$/ do |form|
  page.should have_selector("form##{form_to_id(form)}")
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
    fill_in(field, :with => value, :match => :prefer_exact)
  end
end

When /^(?:|I )fill in "([^"]*)" number (.*?) with "([^"]*)"(?: within "([^"]*)")?$/ do |field, index, value, selector|
  with_scope(selector) do
    selected_select = page.all(:xpath, '//input[@id="'+field+'"]')[index.to_i].set(value)
  end
end

When /^(?:|I )choose "([^"]*)"(?: within "([^"]*)")?$/ do |field, selector|
  with_scope(selector) do
    choose(field)
  end
end

Then /^the( hidden)? "([^"]*)" field(?: within "([^"]*)")? should( not)? contain "([^"]*)"$/ do |visibility, field, selector, negate, value|
  with_scope(selector) do
    field = visibility ? find_field(field, :visible=>false) : find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should_not
      negate ? field_value.should_not =~ /#{value}/ : field_value.should =~ /#{value}/
    else
      negate ? assert_no_match(/#{value}/, field_value) : assert_match(/#{value}/, field_value)
    end
  end
end

Then /^show me the page$/ do
  save_and_open_page
end

Then /^I should see the error "([^\"]*)"$/ do |error|
  page.should have_content error
end

Then /^I should( not)? see the message "([^\"]*)"$/ do |negate, message|
  negate ? (page.should_not have_selector ".dri_messages_container", text: message) : (page.should have_selector ".dri_messages_container", text: message)
end

Then /^I should (not )?see an element "([^"]*)"$/ do |negate, selector|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_css(selector))
end

Then /^I should see the iframe "([^\"]+)"$/ do |iframe_name|
  within_frame(iframe_name){
    sleep 5
    page.status_code.should be 200
  }
end

Then /^I should see a section with id "([^\"]+)"$/ do |div_name|
  selector = "div#" + div_name
  page.should have_selector(selector)
end

When /^I accept the alert$/ do
  page.driver.browser.switch_to.alert.accept
end

Then /^the radio button "(.*?)" should (not )?be "(.*?)"$/ do |field, negate, status|
  negate ? (find_by_id(field).should_not be_checked) : (find_by_id(field).should be_checked)
end

Then /^the "([^"]*)" drop-down should( not)? contain the option "([^"]*)"$/ do |id, negate, value|
  expectation = negate ? :should_not : :should
  page.send(expectation,  have_xpath("//select[@id = '#{select_box_to_id(id)}']/option[@value = '#{value}']"))
end

Then /^I should see the image "(.*?)"$/ do |src|
  page.should have_xpath("//img[contains(@src, \"#{src}\")]")
end
