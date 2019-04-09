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
  matcher = ['.dri_title_dropdown', { text: /^#{regexp}$/, minimum: 0 }]
  within find(:xpath, "//div[@id='facets']") do
    element = page.find(:css, *matcher)
    while better_match = element.first(:css, *matcher)
      element = better_match
    end
    element.click

    with_scope("div.#{facetid}") do
      find('li', text: search).click
    end
  end
end


When /^I select "([^\"]+)" in facet "([^\"]+)" with id "([^\"]+)"$/ do |search, facetname, facetid|
  find("#facets .dri_title_dropdown", text: facetname).click
  check("f_inclusive_#{facetid.remove('blacklight-')}_#{search.split(' ').join('-')}")
end

Then /^I should see "([^\"]+)" in facet with id "([^\"]+)"$/ do |search, facetid|
  selector = "#facets #facet-#{facetid.remove('blacklight-')} .facet-values .selected"
  expect(find(selector).text).to include(search)
end



