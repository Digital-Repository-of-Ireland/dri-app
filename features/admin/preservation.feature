Feature: Preservation

  In order to preserve Digital Objects
  When I create and manipulate collections and objects
  The AIP will reflect the changes

  Background:
    Given I am logged in as "user1" in the group "cm"

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

  Scenario: Publish collection 

  Scenario: Create an object

  Scenario: Edit object metadata

  Scenario: Replace object metadata?

  Scenario: Upload an asset

  Scenario: Replace asset

