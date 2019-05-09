@users @req-23 @done @req-22.2
Feature: User sign up

  In order for the digital repository to control access to digital objects
  As a user
  I want to be able to create and manage an account

Scenario: Navigate to the Sign in page
  Given I am not logged in
  When I go to "the home page"
  Then I should see a link to user profile
  When I follow the link to user profile
  Then I should be on the User Signin page

Scenario: Navigate to the Sign up page
  Given I am not logged in
  When I go to "the home page"
  Then I should see a link to user profile
  When I follow the link to user profile
  Then I should be on the User Signin page
  When I follow the link to sign up
  Then I should be on the User Sign up page

Scenario: Creating a new valid user account
  Given I am not logged in
  Given the group "registered" exists
  Given I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should see a success message for new account
  When I have confirmed the email "validuser@validdomain.com"
  Given I am on the User Signin page
  When I submit the User Sign in page with credentials "validuser@validdomain.com" and "password"
  Then I should be logged in

Scenario: Creating an invalid user account with duplicate email
  Given an account for "user1" already exists
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit the User Sign up page with email "user1@user1.com" and password "password1"
  Then I should see a failure message for duplicate email

Scenario: Creating an invalid user account with non-matching password confirmation
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email address and non-matching password and password confirmation
  Then I should see a failure message for password mismatch

Scenario: Creating an invalid user account with too short password
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email address and too short password and password confirmation
  Then I should see a failure message for too short password

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
  Then I should see a failure message for invalid email or password

Scenario: Logging out
  Given I am logged in as "user1" with password "password1"
  And I am on the user profile page
  Then I should see a link to sign out
  When I follow the link to sign out
  Then I should be logged out

Scenario: A user should be able to edit their details
  Given I am logged in as "user1" with password "password1"
  And I am on the home page
  Then I should see a link to view my account
  And I follow the link to view my account
  Then I should see a link to edit my account
  When I follow the link to edit my account
  Then I should see the edit page
  When I fill in "user_password" with "password2"
  And I fill in "user_password_confirmation" with "password2"
  And I fill in "user_current_password" with "password1"
  And I submit the Edit User form
  Then my authentication details should be updated from "user1", "password1" to "user1", "password2"

#Scenario: A user should be able to cancel their account
#  Given I am logged in as "user1" with password "password1" and accept cookies
#  Then I should see a link to view my account
#  And I follow the link to view my account
#  Then I should see a link to edit my account
#  When I follow the link to edit my account
#  Then I should see a link to cancel my account
#  When I follow the link to cancel my account
#  And I confirm account cancellation
#  Then my account should be deleted
#  And I should be logged out

Scenario: A user should be able to recover their password
# Not sure how to test this as it involves sending an email...

@javascript 
Scenario: an admin user creates a new user account
  Given I am logged in as "adminuser" in the group "admin"
  And I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should be logged in as "adminuser"
