Then /^I should see a search result "(.*?)"$/ do |text|
  expect(page).to have_content(text)
end

Then /^I should not see a search result "(.*?)"$/ do |text|
 expect(page).to_not have_content(text)
end

When /^I search for "(.*?)" in facet "(.*?)" with id "(.*?)"$/ do |search,facetname,facetid|
  regexp = Regexp.escape(facetname)
  # minimum: 0 capybara returns nil instead of throwing an exception if a new element is not found
  matcher = ['.dri_title_dropdown', { text: /^#{regexp}$/, minimum: 0 }]
  within find(:xpath, "//div[@id='facets']") do
    element = page.find(:css, *matcher)
    while better_match = element.first(:css, *matcher)
      element = better_match
    end
    element.click

    within("div.#{facetid}") do
      click_on search
    end
  end
end

