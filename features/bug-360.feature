@bug
Feature: Bug-360

Scenario: Creating a new valid user account
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should see a success message for new account
  And I should be logged in


