@javascript
Feature:
  As an admin user I should be able to configure available end-user licences

  As a user with manage permissions on a collection I should be able to choose a licence for my collection

  As any type of user I should be able to see the licence under which an object is distributed


  Background:
    Given I am logged in as "admin" in the group "admin"
    And a collection with pid "dri:lcoll" and title "Licence Test Collection" created by "admin@admin.com"
    And a Digital Object with pid "dri:lobj" and title "Licence Test Object"
    And the object with pid "dri:lobj" is in the collection with pid "dri:lcoll"

  Scenario: Navigating to the licences pages
    Given I am on the home page
    When I follow the link to admin tasks
    And I follow the link to configure licences
    Then I should see a link to add new licence
    When I follow the link to add new licence
    Then I should see a form for create new licence

  Scenario: Adding a new licence with no logo
    Given I am on the new licence page
    Then I should see a form for create new licence
    When I enter valid licence information for licence "TestLicence" into the new licence form
    And I press the button to add a licence
    Then I should be on the licence index page
    And I should see "TestLicence"

  Scenario: Adding a new licence with url to logo
    Given I am on the new licence page
    Then I should see a form for create new licence
    When I enter valid licence information for licence "TestLicence2" into the new licence form
    And I enter an url to a licence logo
    And I press the button to add a licence
    Then I should be on the licence index page
    And I should see "TestLicence2"

  Scenario: Adding a new licence with uploaded logo
    Given I am on the new licence page
    Then I should see a form for create new licence
    When I enter valid licence information for licence "TestLicence3" into the new licence form
    And I attach the licence logo file "sample_logo.png"
    And I press the button to add a licence
    Then I should be on the licence index page
    And I should see "TestLicence3"

  Scenario: Adding a new licence with virus logo file
    Given I am on the new licence page
    Then I should see a form for create new licence
    When I enter valid licence information for licence "TestLicence4" into the new licence form
    And I upload the logo virus file "sample_virus.png"
    Then I should see a failure message for "virus detected"

  Scenario: Editing a licence
    Given I have created a licence "TestLicence5"
    And I am on the licence index page
    Then I should see "TestLicence5"
    When I follow "Edit Licence"
    When I enter valid licence information for licence "TestLicence6" into the new licence form
    And I press the button to save licence
    Then I should see "TestLicence6"
    And I should not see "TestLicence5"

  Scenario: Associating a licence with a collection
    Given I have created a licence "TestLicence7"
    When I perform a search
    And I follow "Licence Test Collection" within "div.dri_result_container"
    And I follow the link to edit a collection
    Then the "licence" drop-down should contain the option "TestLicence7"
    When I select "TestLicence7" from the selectbox for licence
    And I press the button to save collection changes
    And I go to the "object" "show" page for "dri:lobj"
    Then I should see "TestLicence7"

