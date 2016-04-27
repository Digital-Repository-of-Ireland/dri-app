@javascript
Feature: Institutes
  I should be able to add institutes, associate them with collections,
  and view them in the repository

  Background:
    Given I am logged in as "admin" in the group "admin" and accept cookies

  Scenario: Adding a new institute
    Given I create a collection and save the pid
    And I am on the new organisation page
    When I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I go to the "collection" "show" page for "the saved pid"
    And I follow the link to edit a collection
    Then the "add institute" drop-down should contain the option "TestInstitute"

  Scenario: Associating an institute with a collection
    Given I create a collection and save the pid
    And I am on the new organisation page
    When I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I go to the "collection" "show" page for "the saved pid"
    And I follow the link to manage organisations
    Then the "add institute" drop-down should contain the option "TestInstitute"
    When I select "TestInstitute" from the selectbox for add institute
    And I press the button to "associate an institute"
    Then I should see the image "TestInstitute.png"

  Scenario: Viewing institutes page
    Given I create a collection and save the pid
    And I am on the new organisation page
    When I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I go to the "collection" "show" page for "the saved pid"
    And I follow the link to manage organisations
    When I select "TestInstitute" from the selectbox for add institute
    And I press the button to "associate an institute"
    When I go to "the organisations page"
    Then I should see the image "TestInstitute.png"

  Scenario: viewing associated institutes for an object
    Given I create a collection and save the pid
    And I am on the new organisation page
    When I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I go to the "collection" "show" page for "the saved pid"
    And I follow the link to manage organisations
    When I select "TestInstitute" from the selectbox for add institute
    And I press the button to "associate an institute"
    Then I should see the image "TestInstitute.png"
    When I go to the "collection" "show" page for "the saved pid"
    When I follow the link to add an object
    And I enter valid metadata
    And I press the button to "continue"
    Then I should see the image "TestInstitute.png"
