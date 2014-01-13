Then /^I should see a search result "(.*?)"$/ do |text|
  page.should have_content(text)
end

Then /^I should not see a search result "(.*?)"$/ do |text|
 page.should_not have_content(text)
end

When /^I search for "(.*?)" in facet "(.*?)" with id "(.*?)"$/ do |search,facetname,facetid|
  regexp = Regexp.escape(facetname)
  matcher = ['.dri_title_dropdown', { :text => /^#{regexp}$/ }]
  within find(:xpath, "//div[@id='facets']") do
    element = page.find(:css, *matcher)
    while better_match = element.first(:css, *matcher)
      element = better_match
    end
    element.click

    with_scope("div.#{facetid}") do
      click_on search
    end
  end
end

