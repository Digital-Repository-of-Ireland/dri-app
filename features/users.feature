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
  Then I should see a link to login
  And I should not see a link to logout
  When I follow the link to Login
  Then I should be on the User Signin page

Scenario: Navigate to the Sign up page
  Given I am not logged in
  When I go to the home page
  Then I should see a link to login
  When I follow the link to login
  Then I should be on the User Signin page
  When I follow the link to sign up
  Then I should be on the User Sign up page

Scenario: Creating a new valid user account
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should see the Welcome message 
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
  And I should see invalid email/password error

Scenario: Logging out
  Given I am logged in as "user1" with password "password1"
  When I go to the home page
  Then I should see a link to logout
  When I follow the link to logout
  Then I should be logged out

Scenario: A user should be able to edit their details
  Given I am logged in as "user1" with password "password1"
  Then I should see a link to edit
  When I follow the link to edit
  Then I should see the edit page
  When I fill in "user_email" with "user2@user2.com"
  And I fill in "user_password" with "password2"
  And I fill in "user_password_confirmation" with "password2"
  And I fill in "user_current_password" with "password1"
  And I submit the Edit User form
  Then my authentication details should be updated from "user1", "password1" to "user2", "password2"

Scenario: A user should be able to cancel their account
  Given I am logged in as "user1" with password "password1"
  Then I should see a link to edit
  When I follow the link to edit
  Then I should see a link to cancel accont
  When I follow the link to cancel account
  And I confirm account cancellation
  Then my account should be deleted
  And I should be logged out

Scenario: A user should be able to recover their password
# Not sure how to test this as it involves sending an email...
