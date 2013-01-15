Given /^I am logged in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  user = User.create(:email => email, :password => "password", :password_confirmation => "password")
  visit new_user_session_path
  fill_in("user_email", :with => email) 
  fill_in("user_password", :with => "password") 
  click_button("Sign in")
  step 'I should see "Log Out"'
end

Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  email = "#{login}@#{login}.com"
  user = User.create(:email => email, :password => password, :password_confirmation => password)
  visit new_user_session_path
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button("Sign in")
  step 'I should see "Log Out"'
end

Then /^I should see an edit link for "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  page.should have_link(email, href: "/users/edit")
end

Given /^I am not logged in$/ do
  page.driver.submit :delete, "/users/sign_out", {}
end

Given /^an account for "([^\"]*)" already exists$/ do |login|
  email = "#{login}@#{login}.com"
  user = User.create(:email => email, :password => "password", :password_confirmation => "password")
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

When /^I submit the User Sign up page with email "([^\"]*)"$/ do |email|
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

When /^I submit the User Sign in page with credentials "([^\"]*)" and "([^\"]*)"$/ do |email, password|
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button 'Sign in'
end

Then /^I should be logged in$/ do
step 'I should see a link to "/users/sign_out" with text "Log Out"'
end

Then /^I should be logged out$/ do
  step 'I should see a link to "/users/sign_in" with text "Login"'
end

When /^I follow the edit link for "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  click_link( email )
end

Then /^I should see the edit page$/ do
  page.should have_content("Edit User")
end

When /^I submit the Edit User form$/ do
  click_button 'Update'
end

Then /^my authentication details should be updated from "([^\"]*)", "([^\"]*)" to "([^\"]*)", "([^\"]*)"$/ do |oldlogin, oldpassword, newlogin, newpassword|
  oldemail = "#{oldlogin}@#{oldlogin}.com"
  newemail = "#{newlogin}@#{newlogin}.com"
  page.should have_content( newemail )
  click_link 'Log Out'
  visit new_user_session_path
  fill_in("user_email", :with => oldemail)
  fill_in("user_password", :with => oldpassword)
  click_button("Sign in")
  step 'I should see the error "Invalid email or password"' 
  step 'I should be logged out'
  fill_in("user_email", :with => newemail)
  fill_in("user_password", :with => newpassword)
  click_button("Sign in")
  step 'I should be logged in'
end

Then /^I should see a link with text "([^\"]*)"$/ do |arg1|
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


