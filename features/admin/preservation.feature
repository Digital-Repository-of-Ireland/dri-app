@javascript
Feature: Preservation

  In order to preserve Digital Objects
  When I create and manipulate collections and objects
  The AIP will reflect the changes

  Background:
    Given I am logged in as "user1" in the group "cm" and accept cookies

  Scenario: Create a collection
    When I create a collection and save the pid
    Then an AIP should exist for the saved pid 
    And the AIP for the saved pid should have "1" version
    And the manifest for version "1" for the saved pid should be be valid

  Scenario: Edit collection metadata
    When I create a collection and save the pid 
    When I go to the "collection" "show" page for "the saved pid"
    And I follow the link to edit a collection
    And I enter valid metadata with title "Test Edit"
    And I press the button to "save collection changes"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  Scenario: Replace collection metadata
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to edit
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  @noexec
  Scenario: Add collection cover image
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to add a cover image
    And I attach the cover image file "sample_image.png"
    And I press the button to "save cover image"
    And I wait for the ajax request to finish
    Then I should see a success message for updating a collection
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  @noexec
  Scenario: Publish collection 
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to publish collection
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  Scenario: Add a licence for a collection
    Given I have created a licence "Test"
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to associate a licence
    And I select "Test" from the selectbox for licence 
    And I press the button to "set licence"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  @noexec
  Scenario: Delete an unpublished collection
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to delete a collection
    And I press the button to "confirm delete collection"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  Scenario: Add institutes for a collection
    Given I have created an institute "Test"
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to manage organisations
    And I press the button to "associate an institute"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  Scenario: Create an object
    When I create an object and save the pid
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "1" version 
    And the manifest for version "1" for the saved pid should be be valid

  Scenario: Edit object metadata
    When I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I follow the link to edit an object
    And I enter valid metadata with title "Test Edit"
    And I press the button to "save changes"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  Scenario: Replace object metadata
    When I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I follow the link to edit
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  @noexec
  Scenario: Upload an asset
    When I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "upload a file"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  @noexec
  Scenario: Replace asset
    When I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "upload a file"
    And I go to the "object" "show" page for "the saved pid"
    And I follow the link to view asset tools
    And I follow the link to view asset details
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "upload a file"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "3" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid
    And the manifest for version "3" for the saved pid should be be valid

  Scenario: Mark object as reviewed
    When I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I press the button to "update status"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid

  @noexec
  Scenario: Delete an unpublished object
    When I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I follow the link to delete an object
    And I press the button to "confirm delete object"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be be valid
    And the manifest for version "2" for the saved pid should be be valid
