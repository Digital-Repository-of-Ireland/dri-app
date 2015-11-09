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

  Scenario: Edit collection metadata
    When I create a collection and save the pid 
    When I go to the "collection" "show" page for "the saved pid"
    And I follow the link to edit a collection
    And I enter valid metadata with title "Test Edit"
    And I press the button to "save collection changes"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Replace collection metadata
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Add collection cover image
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to add a cover image
    And I attach the cover image file "sample_logo.png"
    And I press the button to "save cover image"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Publish collection 
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to publish collection
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Add a licence for a collection

  Scenario: Delete an unpublished collection
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to delete a collection
    And I press the button to "confirm delete collection"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Add institutes for a collection
    Given I have created an institute "Test"
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to manage organisations
    And I press the button to "associate an institute"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Create an object
    When I create a collection and save the pid
    And I create an object and save the pid
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "1" version 

  Scenario: Edit object metadata
    When I create a collection and save the pid
    And I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I follow the link to edit an object
    And I enter valid metadata with title "Test Edit"
    And I press the button to "save changes"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Replace object metadata
    When I create a collection and save the pid
    And I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Upload an asset
    When I create a collection and save the pid
    And I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "upload a file"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions

  Scenario: Replace asset
    When I create a collection and save the pid
    And I create an object and save the pid
    And I go to the "object" "show" page for "the saved pid"
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
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

