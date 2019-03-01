@javascript
Feature: DOI Feature
  Published objects will have a DOI. Editing these objects should show a warning.

  Background:
    Given I am logged in as "admin" in the group "admin" and accept cookies
    When I create an object and save the pid
    And the object has a doi
    And the collection with pid "the saved pid" is published
    And the collection has a doi

  Scenario: User should receive a warning when editing a published object
    When I go to the "object" "modify" page for "the saved pid"
    And I follow the link to edit
    And I follow the link to edit an object
    Then I should see the message "Please note that you are editing a published object"

  Scenario: User should receive a warning when editing a published collection
    When I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to edit
    And I follow the link to edit a collection
    Then I should see the message "Please note that you are editing a published object"

  Scenario: User should receive a warning when replacing metadata of a published object
    When I go to the "object" "modify" page for "the saved pid"
    And I follow the link to edit
    And I click "#metadata_uploader"
    Then I should see a dialog with text "Please note that you are editing a published object"

  Scenario: User should receive a warning when replacing metadata of a published collection
    When I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to edit
    And I click "#metadata_uploader"
    Then I should see a dialog with text "Please note that you are editing a published object"

  Scenario: User should receive a warning when adding asset to a published object
    When I go to the "object" "modify" page for "the saved pid"
    And I click "#file_uploader"
    Then I should see a dialog with text "Please note that you are editing a published object"

  Scenario: User should receive a warning when replacing asset on a published object
    When I go to the "object" "modify" page for "the saved pid"
    And I attach the asset file "sample_pdf.pdf"
    And I press the button to "upload a file"
    When I follow the link to view assets
    And I follow the link to view asset details
    And I click "#replace_file"
    Then I should see a dialog with text "Please note that you are editing a published object"
