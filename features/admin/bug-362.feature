@bug
Feature: Bug-362

Scenario: Logging out
  Given I am logged in as "user1" with password "password1"
  And I am on the user profile page
  Then I should see a link to sign out
  When I follow the link to sign out
  Then I should be logged out

