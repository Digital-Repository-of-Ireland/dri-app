@noexec
Feature: Workflows for an edit user

  Background:
    Given I am logged in as a user with manage permissions on a collection

  Scenario: Navigating to the collection page
    Given I am on the home page
    When I click on the link to 'My Collections'
    Then I should see a list of collections
    When I click on the link for the collection
    Then I should see the collection page
    When I click on the link to edit the collection
    Then I should see the edit collection form

  Scenario: Adding edit users
    Given I am on the edit collection page
    When I enter a new user into the edit users list
    And I press the button to "save changes"
    Then the new user should have edit permissions on the collection

  Scenario: Adding manager users
    Given I am on the edit collection page
    When I enter a new user into the manager users list
    And I press the button to "save changes"
    Then the new user should have manager permissions on the collection
