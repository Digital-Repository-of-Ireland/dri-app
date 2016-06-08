@javascript
Feature: Institutes
  I should be able to add institutes, associate them with collections,
  and view them in the repository

  Background:
    Given I am logged in as "admin" in the group "admin" and accept cookies
    And a collection with pid "instcoll" and title "Institute Test Collection"
    And a Digital Object with pid "instobj" and title "Institute Test Object"
    And the object with pid "instobj" is in the collection with pid "instcoll"

  Scenario: Adding a new institute
    Given I am on the new organisation page
    When I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I am on the home page
    And I perform a search
    And I follow the link to browse
    And I follow "Institute Test Collection" within "div.dri_result_container"
    And I follow the link to edit a collection
    Then the "add institute" drop-down should contain the option "TestInstitute"

  Scenario: Associating an institute with a collection
    Given I am on the new organisation page
    When I fill in "institute[name]" with "TestInstitute"
    And I fill in "institute[url]" with "http://www.dri.ie/"
    And I attach the institute logo file "sample_logo.png"
    And I press the button to "add an institute"
    When I perform a search
    And I follow the link to browse
    And I follow "Institute Test Collection" within "div.dri_result_container"
    And I follow the link to manage organisations
    Then the "add institute" drop-down should contain the option "TestInstitute"
    When I select "TestInstitute" from the selectbox for add institute
    And I press the button to "associate an institute"
    Then I should see the image "sample_logo.png"

  Scenario: Viewing associated institutes for a collection
    Given I have associated the institute "TestInstitute" with the collection with pid "instcoll"
    When I perform a search
    And I follow the link to browse
    And I follow "Institute Test Collection" within "div.dri_result_container"
    Then I should see the image "sample_logo.png"

  Scenario: Viewing institutes page
    Given I have associated the institute "TestInstitute" with the collection with pid "instcoll"
    When I go to "the organisations page"
    Then I should see the image "TestInstitute"

  Scenario: viewing associated institutes for an object
    Given I have associated the institute "TestInstitute" with the collection with pid "instcoll"
    When I go to the "object" "show" page for "instobj"
    Then I should see the image "sample_logo.png"
