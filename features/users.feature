@users
Feature:
  
  In order for the digital repository to control access to digital objects
  As a user
  I want to be able to create and manage an account

Before do
  DatabaseCleaner.start
end

After do |scenario|
  DatabaseCleaner.clean
end

Scenario: Navigate to the Sign in page
  Given I am not logged in
  When I go to the home page
  Then I should see a link to "/users/sign_in" with text "Login"
  And I should not see a link to "Log Out"
  When I follow "Login"
  Then I should be on the User Signin page

Scenario: Navigate to the Sign up page
  Given I am not logged in
  When I go to the home page
  Then I should see a link to "/users/sign_in" with text "Login"
  When I follow "Login"
  Then I should be on the User Signin page
  When I follow "Sign up"
  Then I should be on the User Sign up page

Scenario: Creating a new valid user account
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should see the message "Welcome! You have signed up successfully." 
  And I should be logged in

Scenario: Creating an invalid user account with duplicate email
  Given an account for "user1" already exists
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit the User Sign up page with email "user1@user1.com" and password "password1"
  Then I should see the error "Email has already been taken"
  And I should be logged out

Scenario: Creating an invalid user account with non-matching password confirmation
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email address and non-matching password and password confirmation
  Then I should see the error "Password doesn't match confirmation" 
  And I should be logged out

Scenario: Creating an invalid user account with too short password
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email address and too short password and password confirmation
  Then I should see the error "Password is too short" 
  And I should be logged out

Scenario: User signs in with valid credentials
  Given an account for "user1" already exists
  Given I am not logged in
  Given I am on the User Signin page
  When I submit the User Sign in page with credentials "user1@user1.com" and "password"
  Then I should be logged in
  
Scenario: User signs in with invalid credentials 
  Given I am not logged in
  Given I am on the User Signin page
  When I submit the User Sign in page with credentials "user1@user1.com" and "badpassword"
  Then I should be logged out
  And I should see the error "Invalid email or password"

Scenario: Logging out
  Given I am logged in as "user1" with password "password1"
  When I go to the home page
  Then I should see a link to "/users/sign_out" with text "Log Out"
  When I follow "Log Out"
  Then I should be logged out

Scenario: A user should be able to edit their details
  Given I am logged in as "user1" with password "password1"
  Then I should see an edit link for "user1"
  When I follow the edit link for "user1"
  Then I should see the edit page
  When I fill in "user_email" with "user2@user2.com"
  And I fill in "user_password" with "password2"
  And I fill in "user_password_confirmation" with "password2"
  And I fill in "user_current_password" with "password1"
  And I submit the Edit User form
  Then my authentication details should be updated from "user1", "password1" to "user2", "password2"

Scenario: A user should be able to cancel their account
  Given I am logged in as "user1" with password "password1"
  Then I should see an edit link for "user1"
  When I follow the edit link for "user1"
  Then I should see a link to "/users" with text "Cancel my account"
  When I follow "Cancel my account"
  And I confirm account cancellation
  Then my account should be deleted
  And I should be logged out

Scenario: A user should be able to recover their password

