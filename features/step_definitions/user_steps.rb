Given /^I am logged in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  @user.confirm
  delete destroy_user_session_path(@user)
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" and accept cookies$/ do |login|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  @user.confirm
  delete destroy_user_session_path(@user)
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  step 'I accept cookies terms'
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" in the group "([^\"]*)"$/ do |login, group|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png')) if User.find_by_email(email).nil?
  @user.confirm
  @user.save
  group_id = UserGroup::Group.find_or_create_by(name: group, description: "Test group", is_locked: true).id
  membership = @user.join_group(group_id)
  membership.approved_by = @user.id
  membership.save
  delete destroy_user_session_path(@user)
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" in the group "([^\"]*)" and accept cookies$/ do |login, group|
  email = "#{login}@#{login}.com"
  if User.find_by_email(email).nil?
    @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
    @user.confirm
    @user.save
  else
    @user = User.find_by_email(email)
    @user.confirm
  end
  group_id = UserGroup::Group.find_or_create_by(name: group, description: "Test group", is_locked: true).id
  membership = @user.join_group(group_id)
  membership.approved_by = @user.id
  membership.save
  delete destroy_user_session_path(@user)
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  step 'I accept cookies terms'
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => password, :password_confirmation => password, :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  @user.confirm
  delete destroy_user_session_path(@user)
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" with password "([^\"]*)" and accept cookies$/ do |login, password|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => password, :password_confirmation => password, :locale => "en", :first_name => "fname", :second_name => "sname", :image_link => File.join(cc_fixture_path, 'sample_image.png'))
  @user.confirm
  delete destroy_user_session_path(@user)  
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  step 'I accept cookies terms'
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" with language "([^\"]*)"$/ do |login, lang|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :locale => lang, :first_name => "fname", :second_name => "sname")
  @user.confirm
  delete destroy_user_session_path(@user)
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Login")
  step 'I should be logged in'
end

Given /^I am logged in as "([^\"]*)" with no language$/ do |login|
  email = "#{login}@#{login}.com"
  @user = User.create(:email => email, :password => "password", :password_confirmation => "password", :first_name => "fname", :second_name => "sname")
  @user.confirm
  delete destroy_user_session_path(@user)  
  visit path_to("sign in")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "password")
  click_button("Login")
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
  user.confirm
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

When /^I have confirmed the email "([^\"]*)"$/ do |email|
  user = User.find_by_email(email)
  user.confirm
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
  click_button 'Login'
end

Then /^I should be logged in$/ do
  step 'I should have a cookie _dri-app_session'
  step 'I am on the user profile page'
  step 'I should see a link to sign out'
end

Then /^I should be logged out$/ do
  step 'I am on the user profile page'
  step 'I should see a button to sign in'
end

Then /^I should be logged in as "(.*?)"$/ do |login|
  step 'I should be logged in'
  find('#view_account').trigger('click')
  page.should have_content(login)
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
  step 'I am not logged in'
  visit path_to("sign in")
  fill_in("user_email", :with => oldemail)
  fill_in("user_password", :with => oldpassword)
  click_button("Login")
  step 'I should see the error "Invalid email or password"'
  fill_in("user_email", :with => newemail)
  fill_in("user_password", :with => newpassword)
  click_button("Login")
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

