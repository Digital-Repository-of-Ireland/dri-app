Given /^my browser language is "([^"]*)"$/ do |lang|
   page.driver.browser.header('Accept-Language', lang)

end

Then /^I should see the ([^"]*) language$/ do |lang|
  page.should have_content( I18n.t('dri.headerlinks.home', :locale => lang) )
end

When /^I change my language to ([^"]*)$/ do |lang|
  fill_in("user_current_password", :with => "password")
  step "I select #{lang} from the selectbox for language"
  step 'I press the button to update language'
end
