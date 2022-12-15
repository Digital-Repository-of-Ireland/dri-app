Then /^I should see a search result "(.*?)"$/ do |text|
  expect(page).to have_content(text)
end

Then /^I should not see a search result "(.*?)"$/ do |text|
 expect(page).to_not have_content(text)
end

Then /^I should see (\d+) collection(?:s)? with title(?:s)? "([^\"]+)"$/ do |num, titles|
  collections = find_all('.dri_content_block_collection', visible: true)
  expect(collections.length).to eq(num)

  titles_arr = titles.split(',').map(&:strip)
  expect(titles_arr.length).to eq(num)

  collection_titles = collections.map { |col| col.find('h1').text }
  expect(collection_titles.sort).to eq(titles_arr.sort)
end

When /^I search for "(.*?)" in facet "(.*?)" with id "(.*?)"$/ do |search, facetname, facetid|
  regexp = Regexp.escape(facetname)
  # minimum: 0 capybara returns nil instead of throwing an exception if a new element is not found
  within find(:xpath, "//div[@id='facets']") do
    element = page.find(:css, '.dri_title_dropdown', text: /^#{regexp}$/, minimum: 0)
    while better_match = element.first(:css, '.dri_title_dropdown', text: /^#{regexp}$/, minimum: 0)
      element = better_match
    end
    element.click

    within("div.#{facetid}") do
      click_on search
    end
  end
end

Then /^I should see "([^\"]+)" in facet with id "([^\"]+)"$/ do |search, facetid|
  selector = "#facets #facet-#{facetid.remove('blacklight-')} .facet-values .selected"
  expect(find(selector).text).to include(search)
end

Then /^I should( not)? see "([^\"]+)" in the facet well$/ do |negate, text|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_css('#dri_facet_restrictions_container_id li', text: text))
end
