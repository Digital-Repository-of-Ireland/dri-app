@javascript
Feature: Read Only
  The repository can be set to read only and edits will be disabled

  Background:
    Given I am logged in as "user1" in the group "cm" and accept cookies
    And the repository is set to read only

  @read_only
  Scenario: see message correct
    Given I am on the home page
    And I follow the link to the workspace page
    And I follow the link to add a new collection
    Then I should see the message "Repository is currently undergoing maintenance. Updates are temporarily disabled."
