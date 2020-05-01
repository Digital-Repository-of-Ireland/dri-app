@wip
Feature: Features for a collection manager

  Background:
    given I am logged in as "cmuser" in the group "cm"

  Scenario: Create collections via the web forms
    Given I am on the home page
    When I click on the link to add a collection
    And I select the metadata type
    And I enter a title
    And I select a deposit agreement
    And I agree to the deposit agreement
    And I enter one or more manager users
    And I click on save
    Then the collection should be created

  Scenario: view a report showing activity on their collections
    Given I am on the home page
    When I click on report
    Then I should see a report which has yet to be specced out

  Scenario: Create collections via the command line
    Pending: this is handled elsewhere
