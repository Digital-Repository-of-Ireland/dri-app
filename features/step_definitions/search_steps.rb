Then /^I should see a search result "(.*?)"$/ do |text|
  page.should have_content(text)
end

Then /^I should not see a search result "(.*?)"$/ do |text|
 page.should_not have_content(text)
end

When /^I search for "(.*?)" in facet "(.*?)" with id "(.*?)"$/ do |search,facetname,facetid|
  within find(:xpath, "//div[@id='facets']") do
    click_on facetname
    with_scope("div.#{facetid}") do
      click_on search
    end
  end
end
