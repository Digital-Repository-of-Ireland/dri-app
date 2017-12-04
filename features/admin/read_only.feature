@javascript @readonly
Feature: Read Only
  The repository can be set to read only and edits will be disabled

  Background:
    Given I am logged in as "user1" in the group "cm" and accept cookies
    And the repository is set to read only

  Scenario: see maintenance message when read-only flag is set
    Given I am on the workspace page
    And I follow the link to add a new collection
    Then I should see the message "Repository is currently undergoing maintenance. Updates are temporarily disabled."
