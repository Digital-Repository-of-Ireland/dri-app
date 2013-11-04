Then /^I should see a search result "(.*?)"$/ do |text|
  page.should have_content(text)
end

Then /^I should not see a search result "(.*?)"$/ do |text|
 page.should_not have_content(text)
end

When /^I search for "(.*?)" with "(.*?)"$/ do |search,facet|
  within find(:xpath, "//div[@id='facets']") do
    click_on facet
    click_on search
  end
end
