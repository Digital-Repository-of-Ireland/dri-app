Given /^I am logged in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  user = User.create(:email => email, :password => "password", :password_confirmation => "password")
  visit new_user_session_path
  fill_in("user_email", :with => email) 
  fill_in("user_password", :with => "password") 
  click_button("Sign in")
  step 'I should see "Log Out"'
end

Then /^I should see an edit link for "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  page.should have_link(email, href: "/users/edit")
end

Given /^I am not logged in$/ do
request = Net::HTTP::Delete.new("/users/sign_out")
#  visit destroy_user_session_path
end

Given /^an account for "([^\"]*)" already exists$/ do |email|
  user = User.create(:email => email, :password => "password", :password_confirmation => "password")
  visit new_user_session_path
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Sign in")
end

When /^I got to the home page$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I submit a valid email, password and password confirmation$/ do
  email = "validuser@validdomain.com"
  password = "password"
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password)
  click_button 'Sign up'
end

When /^I submit the User Sign up page with email "(.*?)"$/ do |email|
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  fill_in("user_password_confirmation", :with => "password")
  click_button 'Sign up'
end

When /^I submit a valid email address and non\-matching password and password confirmation$/ do
  email = "validuser@validdomain.com"
  password = "password"
  password_confirmation = "password1"
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password_confirmation)
  click_button 'Sign up'
end

When /^I submit a valid email address and too short password and password confirmation$/ do
  email = "validuser@validdomain.com"
  password = "passw"
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password)
  click_button 'Sign up'
end

When /^I submit the User Sign in page with email "(.*?)"$/ do |email|
  password = "password"
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button 'Sign in'
end

When /^I submit the login form with invalid credentials$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should be logged out$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I follow the edit link for "([^\"]*)"$/ do |login|
  pending # express the regexp above with the code you wish you had
end

Then /^I should see my edit page$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I submit a new email and password$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^my details should be updated$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see a link with text "(.*?)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^I should see a confirmation popup$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I confirm account cancellation$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^my account should be deleted$/ do
  pending # express the regexp above with the code you wish you had
end


