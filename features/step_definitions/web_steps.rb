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

Given /^I have created an object with metadata "(.*?)" in the collection(?: with pid "(.*?)")?$/ do |metadata_file, collection_pid|
  collection_pid = @collection.id unless collection_pid
  steps %{
    When I go to the "metadata" "upload" page for "#{collection_pid}"
    And I attach the metadata file "#{metadata_file}"
    And I press the button to "ingest metadata"
    Then I should see a success message for ingestion
  }
end

Given /^I have created an object with title "(.*?)" in the collection(?: with pid "(.*?)")?$/ do |title, collection_pid|
  collection_pid = @collection.id unless collection_pid
  steps %{
    When I go to the "my collections" "show" page for "#{collection_pid}"
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

When /^I add the asset "([^\"]+)" to "([^\"]+)"$/ do |asset, pid|
  steps %{
    Given I am on the my collections page for id #{pid}
    When I attach the asset file "#{asset}"
    And I press the button to "upload a file"
    Then I should see a success message for file upload
  }
end

# TODO: refactor to use quotes around arg(s) to avoid ambiguous matches
# would need to refactor path_translator too
Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to "([^"]*)"$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to the "([^"]*)" "([^"]*)" page(?: for "([^"]*)")?$/ do |type, page, pid|
  if(pid.nil? && ['my collections', 'collection', 'metadata'].include?(type))
    pid = @collection.id
  elsif(pid.nil? && type == "object")
    pid = @digital_object.id
  elsif (pid.eql?('the saved pid') && (type.eql?("collection") || type == 'my collections'))
    pid = @collection_pid ? @collection_pid : @pid
  elsif (pid.eql?('the saved pid') && type.eql?("object"))
    pid = @pid if pid.eql?('the saved pid')
  end
  visit path_for(type, page, pid)
end

When /^(?:|I )follow the link to (.+)$/ do |link_name|
  if @javascript_driver
    element = page.find_link(link_to_id(link_name), { visible: false})
    page.execute_script("return arguments[0].click();", element)
  else
    page.find_link(link_to_id(link_name)).click
  end
end

# Use this step when overlaping elements might confuse Capybara
# - it ignores overlaping <a> elements and just fires the click
# event on the selected element.
When /^(?:|I )click the link to (.+)$/ do |link_name|
  if @javascript_driver
    element = page.find_link(link_to_id(link_name), { visible: false})
    page.execute_script("return arguments[0].click();", element)
  else
    element = page.find(:id, link_to_id(link_name))
    element.trigger('click')
  end
end

When /^(?:|I )follow "([^"]*)"(?: within "([^"]*)")?$/ do |link, scope|
  with_scope(scope) do
    click_link(link)
  end
end

When /^(?:|I )click the first "([^\"]+)" within "([^"]*)"$/ do |selector, scope|
  within(scope) do
    page.find_all(selector).first.click
  end
end

When /^I select "(.*?)" from the selectbox for (.*?)$/ do |option, selector|
  select_by_value(option, :from => select_box_to_id(selector))
end

When /^I select "(.*?)" from the selectbox number (.*?) for (.*?)$/ do |option, index, selector|
  page.all(:xpath, '//select[@id="'+select_box_to_id(selector)+'"]')[index.to_i].find(:xpath, ".//option[@value='#{option}']").select_option
end

When /^I select the text "(.*?)" from the selectbox for (.*?)$/ do |option, selector|
  select(option, :from => select_box_to_id(selector))
end

When /^I select "([^\"]+)" from "([^\"]+)"$/ do |text, selector|
  find(selector, visible: true).select(text)
end

Then /^I should see "([^\"]+)" selected in "([^\"]+)"$/ do |text, selector|
  expect(page).to have_select(selector, selected: text)
end

When /^I upload the metadata file "(.*?)"$/ do |file|
    attach_file("dri_metadata_uploader", File.expand_path(File.join(cc_fixture_path, file)))
end

When /^I attach the metadata file "(.*?)"$/ do |file|
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

When /^I select the "(objects|collections|sub collections)" tab$/ do |tab|
  click_link(tab.gsub(/\s/, '_'))
end

When /^I hover over a visible "([^\"]+)"$/ do |selector|
  find(selector, visible: true).hover
end

When /^I click "([^\"]+)"$/ do |selector|
  find(selector, visible: true).click
end

# # resque / redis jobs update solr after characterization of asset
# # need to stub response since services aren't running in test
When /^I fake the update to solr to add the asset "([^\"]+)" to "([^\"]+)"$/ do |asset, pid|
  steps %{
    When contains_images? always returns true
    And published_images returns generic files from "#{pid}"
  }
end

When /^contains_images\? always returns true$/ do
  allow_any_instance_of(SolrDocument).to receive(:contains_images?) { true }
end

When /^published_images returns generic files from "([^\"]+)"$/ do |pid|
  obj = ActiveFedora::Base.find(pid)
  generic_files = if obj.collection?
                    obj.governed_items.map(&:generic_files).flatten
                  else
                    obj.generic_files
                  end
  # TODO: only stub for given pid, possibly use block form to check pid?
  # e.g. any_inst_of(...) {|o| o.id == pid}
  allow_any_instance_of(SolrDocument).to receive(:published_images).and_return(
    generic_files.map do |generic_file|
      SolrDocument.new(generic_file.to_solr)
    end
  )
end

When /^I refresh the page$/ do
  # page.driver.browser.navigate.refresh
  visit current_path
end

Then /^I should( not)? see a popover$/ do |negate|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_css('div.popover', visible: true))
end

Then /^I should see a popover with the title "([^\"]+)"$/ do |title|
  expect(page).to have_selector('div.popover .popover-title', visible: true, text: title)
end

Then /^I should see the (valid|modified) metadata$/ do |type|
  case type
    when "valid"
      interface.has_valid_metadata?
    when "modified"
      interface.has_modified_metadata?
  end
end

Then /^I press "(.*?)"$/ do |selector|  
  Capybara.ignore_hidden_elements = false
  # click_on(selector)
  find(selector).click
end

Then /^(?:|I )press the modal button to "(.*?)" in "(.*?)"$/ do |button,modal|
  element = page.find_by_id(modal, :visible=>false).find_by_id(button_to_id(button))
  page.execute_script("return arguments[0].click();", element)
end

Then /^(?:|I )(press|click) the button to "([^"]*)"(?: within "([^"]*)")?$/ do |action, button, id|
  # click should work on hidden elements, press should not
  if action == 'click'
    Capybara.ignore_hidden_elements = false 
    find_args = {visible: :hidden}
  end

  if id
    within("##{id}") do
      page.find_button(button_to_id(button), *find_args).click
    end
  else
    page.find_button(button_to_id(button), *find_args).click
  end
end

Then /^I check "(.*?)"$/ do |checkbox|
  Capybara.ignore_hidden_elements = false
  element = page.find_by_id(checkbox, {visible: false}) #.click #trigger('click')
  page.execute_script("return arguments[0].click();", element)
end

When /^(?:|I )perform a search$/ do
  # Requires javascript
  find(:id, 'q').native.send_keys(:enter)
end

Then /^(?:|I )should( not)? see a button to (.+)$/ do |negate, button|
   negate ? (expect(page).to_not have_button(button_to_id(button))) : (expect(page).to have_button(button_to_id(button)))
end

Then /^(?:|I )should( not)? see a link to (.+)$/ do |negate, link|
  negate ? (expect(page).to_not have_link(link_to_id(link))) : (expect(page).to have_link(link_to_id(link)))
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

Then /^"([^\"]+)" should be selected in "([^\"]+)"$/ do |selected, selector|
  expect(page).to have_select(selector, selected: selected)
end

Then /^(?:|I )should( not)? see a (success|failure) message for (.+)$/ do |negate, success_failure, message|
  # @obj_pid = URI(current_url).path.split('/').last
  expectation = negate ? :should_not : :should
  page.send(expectation, have_selector(".dri_messages_container", text: flash_for(message)))
end

Then /^(?:|I )should( not)? see a message for (.+)$/ do |negate, message|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_selector(".dri_messages_container", text: flash_for(message)))
end

Then /^(?:|I )should( not)? see a window about cookies$/ do |negate|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_selector(".modal-title", text: flash_for("cookie terms")))
end

Then /^(?:|I )should( not)? see a message about cookies$/ do |negate|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_selector(".alert", text: flash_for("cookie notification")))
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

Then /^I should see a link to "([^\"]+)" with text "([^\"]+)"$/ do |url, text|
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

When /^(?:|I )fill in "([^"]*)"(?: within "([^"]*)")?(?: with|for):$/ do |field, selector, value|
  within(selector) do
    fill_in(field, with: value)
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

Then /^the( hidden)? "([^"]*)" field(?: within "([^"]*)")? should( not)? contain "([^"]*)"$/ do |visibility, field_id, selector, negate, value|
  with_scope(selector) do
    # https://www.rubydoc.info/github/teamcapybara/capybara/Capybara/Node/Finders#find-instance_method
    # visible: false returns visible and non-visible elements, use :hidden
    field = if visibility
              find("##{escape_id(field_id)}", visible: :hidden)
              # find_field(field_id, visible: :hidden) # throws exception
            else
              find_field(field_id)
            end
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should_not
      negate ? field_value.should_not =~ /#{value}/ : field_value.should =~ /#{value}/
    else
      negate ? assert_no_match(/#{value}/, field_value) : assert_match(/#{value}/, field_value)
    end
  end
end

Then /^I should see the error "([^\"]*)"$/ do |error|
  page.should have_content error
end

Then /^I should( not)? see the message "([^\"]*)"$/ do |negate, message|
  negate ? (expect(page).to_not have_selector ".dri_messages_container", text: message) : (expect(page).to have_selector ".dri_messages_container", text: message)
end

Then /^I should (not )?see an element "([^"]*)"$/ do |negate, selector|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_css(selector))
end

# used for vocab autocomplete
# .vocab-dropdown always exists, but is hidden. using see element will always pass
Then /^I should (not )?see (\d+) visible element(s)? "([^\"]*)"$/ do |negate, num, _, selector|
  expectation = negate ? :to_not : :to
  expect(find_all(selector, visible: true).count).send(expectation, eq(num))
end

Then /^I should (not )?see a hidden "([^"]*)" within "([^"]*)"$/ do |negate, element, scope|
  expectation = negate ? :to_not : :to
  within(scope) do
    expect(find_all(escape_id(element), visible: :hidden).count).send(expectation, be > 0)
  end
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

Then /^I should see a dialog with text "([^"]*)"$/ do |text|
  page.driver.browser.switch_to.alert.text.should include(text)
end

Then /^the radio button "(.*?)" should (not )?be "(.*?)"$/ do |field, negate, status|
  negate ? (find_by_id(field).should_not be_checked) : (find_by_id(field).should be_checked)
end

Then /^the "([^"]*)" drop-down should( not)? contain the option "([^"]*)"$/ do |id, negate, value|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_xpath("//select[@id = '#{select_box_to_id(id)}']/option[@value = '#{value}']"))
end

Then /^I should( not)? see the image "([^\"]+)"$/ do |negate, src|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_xpath("//img[contains(@alt, \"#{src}\")]"))
end

Then /^the iiif image should have a link that matches "([^\"]+)"$/ do |link|
  # select anchor containing iiif logo
  iiif_logo_link_xpath = "//a[.//img[contains(@alt, 'Iiif logo')]]"
  image_link = find(:xpath, iiif_logo_link_xpath)[:href]
  expect(image_link).to match(link)
end

Then /^the element with id "([^"]*)" should be focused$/ do |id|
  page.evaluate_script("document.activeElement.id").should == id
end

Then /^all "([^\"]+)" within "([^\"]+)" should link to (.+)$/ do |selector, scope, type|
  expect_method = if type.match? /a root collection/
                    :root_collection?
                  elsif type.match? /a collection/
                    :collection?
                  elsif type.match? /an object/
                    :object?
                  else
                    raise ArgumentError, "unrecognized type: #{type}"
                  end

  expect(page).to have_selector(scope)
  within(scope) do
    objects = page.find_all(selector)
    expect(objects.count).to be >= 1
    objects.each do |obj|
      catalog_link = obj.find_link(href: /\/catalog\//)[:href]
      object_pid = catalog_link.split("/catalog/")[-1]
      solr_doc = SolrDocument.find(object_pid)
      expect(solr_doc.send(expect_method)).to be true
    end
  end
end

Then /^"([^\"]+)" should( not)? be disabled$/ do |selector, negate|
  element = find(selector, visible: true)
  expect(element.disabled?).to be !negate
end

Then /^I should( not)? see a modal(?: with title "([^\"]+)")?$/ do |negate, title|
  if negate
    expect(page).to_not have_css('.modal-dialog', visible: true)
  else
    modal = find('.modal-dialog', visible: true)
    if title
      modal_title = modal.find('.modal-title').text
      expect(modal_title).to eq title
    end
  end
end

Then /^I should see an input "([^\"]+)" with text "([^\"]+)" within "([^\"]+)"$/ do |fname, text, selector|
  with_scope(selector) do
    expect(page).to have_field(fname, with: text)
  end
end
