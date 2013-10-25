Given /^I am logged in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Sign in")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" in the group "([^\"]*)"$/ do |login, group|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  @user.save
  group_id = UserGroup::Group.find_or_create_by_name(group, description: "Test group", is_locked: true).id
  membership = @user.join_group(group_id)
  membership.approved_by = @user.id
  membership.save
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Sign in")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => password, :password_confirmation => password, :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button("Sign in")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" with language "([^\"]*)"$/ do |login, lang|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => lang, :first_name => "fname", :second_name => "sname")
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Sign in")
  step 'I should be logged in'
end

Then /^I should see an edit link for "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  page.should have_link(email, href: "/user_groups/users/edit")
end

Given /^I am not logged in$/ do
  step 'I am on the home page'
  Capybara.reset_sessions!
  if Capybara.current_driver.to_s == "rack_test"
    page.driver.submit :delete, "/user_groups/users/sign_out", {}
  end
end

Given /^an account for "([^\"]*)" already exists$/ do |login|
  email = "#{login}@#{login}.com"
  user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname")
end

When /^I submit a valid email, password and password confirmation$/ do
  email = "validuser@validdomain.com"
  password = "password"
  fill_in("user_email", :with => email)
  fill_in("user_first_name", :with => "fname")
  fill_in("user_second_name", :with => "sname")
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password)
  click_button 'Register'
end

When /^I submit the User Sign up page with email "([^\"]*)" and password "([^\"]*)"$/ do |email, password|
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password)
  fill_in("user_first_name", :with => "fname")
  fill_in("user_second_name", :with => "sname")
  click_button 'Register'
end

When /^I submit a valid email address and non\-matching password and password confirmation$/ do
  email = "validuser@validdomain.com"
  password = "password"
  password_confirmation = "password1"
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password_confirmation)
  click_button 'Register'
end

When /^I submit a valid email address and too short password and password confirmation$/ do
  email = "validuser@validdomain.com"
  password = "passw"
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  fill_in("user_password_confirmation", :with => password)
  click_button 'Register'
end

When /^I submit the User Sign in page with credentials "([^\"]*)" and "([^\"]*)"$/ do |email, password|
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button 'Sign in'
end

Then /^I should be logged in$/ do
  step 'I should have a cookie _nuig-rnag_session'
  step 'I should see a link to sign out'
end

Then /^I should be logged out$/ do
  step 'I should see a link to sign in'
end

Then /^I should be logged in as "(.*?)"$/ do |login|
  step 'I should be logged in'
  account_link = page.find_by_id('view_account')
  account_link.should have_content(login)
end

When /^I follow the view link for "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  click_link( email )
end

Then /^I should see the edit page$/ do
  current_path.should == user_group.edit_user_path(@user)
end

When /^I submit the Edit User form$/ do
  click_button 'Update'
end

Then /^my authentication details should be updated from "([^\"]*)", "([^\"]*)" to "([^\"]*)", "([^\"]*)"$/ do |oldlogin, oldpassword, newlogin, newpassword|
  oldemail = "#{oldlogin}@#{oldlogin}.com"
  newemail = "#{newlogin}@#{newlogin}.com"
  page.should have_content( newemail )
  step 'I follow the link to sign out'
  step 'I should be logged out'
  visit path_to("sign in")
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

When /^I confirm account cancellation$/ do
  def handle_js_confirm(accept=true)
    page.evaluate_script "window.original_confirm_function = window.confirm"
    page.evaluate_script "window.confirm = function(msg) { return #{!!accept}; }"
    yield
  ensure
    page.evaluate_script "window.confirm = window.original_confirm_function"
  end
end

Then /^my account should be deleted$/ do
  step 'I should see the message "Your account has been deleted"'
  step 'I should be logged out'
end

