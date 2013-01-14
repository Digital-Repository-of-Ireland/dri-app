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
