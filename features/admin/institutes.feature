@javascript
Feature: Institutes
  I should be able to add institutes, associate them with collections,
  and view them in the repository

  Background:
    Given I am logged in as "admin" in the group "admin" and accept cookies
    #And I create a collection and save the pid

  Scenario: Adding a new institute
    Given I create a collection and save the pid
    When I am on the new organisation page
    And I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to manage organisations
    Then the "add institute" drop-down should contain the option "TestInstitute"

  Scenario: Viewing associated institutes for a collection
    Given I create a collection and save the pid
    And I have associated the institute "TestInstitute" with the collection with pid "the saved pid"
    When I go to the "collection" "show" page for "the saved pid"
    Then I should see the image "TestInstitute"

  Scenario: Viewing institutes page
    Given I create a collection and save the pid
    And I have associated the institute "TestInstitute" with the collection with pid "the saved pid"
    And the collection with pid "the saved pid" is published
    When I go to "the organisations page"
    Then I should see the image "TestInstitute"

  Scenario: viewing associated institutes for an object
    Given I create a collection and save the pid
    And I create an object and save the pid
    And I have associated the institute "TestInstitute" with the collection with pid "the saved pid"
    When I go to the "object" "show" page for "the saved pid"
    Then I should see the image "TestInstitute"
