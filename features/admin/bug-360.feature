@bug
Feature: Bug-360

Scenario: Creating a new valid user account
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should see a success message for new account
  When I have confirmed the email "validuser@validdomain.com"
  Given I am on the User Signin page
  When I submit the User Sign in page with credentials "validuser@validdomain.com" and "password"  
  Then I should be logged in
