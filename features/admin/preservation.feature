@javascript
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
    And the manifest for version "1" for the saved pid should be valid

  Scenario: Edit collection metadata
    When I create a collection and save the pid
    When I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to edit a collection
    And I enter valid metadata for a collection with title Test Edit
    And I press the button to "save collection changes"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  Scenario: Replace collection metadata
    When I create a collection and save the pid
    And I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to edit
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  @noexec
  Scenario: Add collection cover image
    When I create a collection and save the pid
    And I go to the "collection" "edit" page for "the saved pid"
    And I attach the cover image file "sample_image.png"
    And I press the button to "save collection changes"
    Then I should see a success message for updating a collection
    And an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  @noexec
  Scenario: Publish collection
    Given I have created an institute "Test"
    When I create a collection and save the pid
    And I have associated the institute "Test" with the collection with pid "the saved pid"
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to publish collection
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  @noexec
  Scenario: Add a licence for a collection
    Given I have created a licence "Test"
    When I create a collection and save the pid
    And I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to associate a licence
    And I select "Test" from the selectbox for licence
    And I press the button to "set licence"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  @noexec
  Scenario: Delete an unpublished collection
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to delete a collection
    And I press the button to "delete collection with the saved pid"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  @noexec
  Scenario: Add institutes for a collection
    Given I have created an institute "Test"
    When I create a collection and save the pid
    And I go to the "my collections" "show" page for "the saved pid"
    And I follow the link to manage organisations
    And I press the button to "associate an institute"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  Scenario: Create an object
    When I create an object and save the pid
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "1" version
    And the manifest for version "1" for the saved pid should be valid

  Scenario: Edit object metadata
    When I create an object and save the pid
    And I go to the "object" "modify" page for "the saved pid"
    And I follow the link to edit an object
    And I enter valid metadata with title "Test Edit"
    And I press the button to "save changes"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  Scenario: Replace object metadata
    When I create an object and save the pid
    And I go to the "object" "modify" page for "the saved pid"
    And I follow the link to edit
    And I attach the metadata file "SAMPLEA.xml"
    And I press the button to "upload metadata"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  Scenario: Upload an asset
    When I create an object and save the pid
    And I go to the "asset" "new" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "Upload 1 file"
    Then I should see "Asset has been successfully uploaded."
    And I should see a success message in the asset upload table for file upload
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  Scenario: Replace asset
    When I create an object and save the pid
    And I go to the "asset" "new" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "Upload 1 file"
    Then I should see "Asset has been successfully uploaded."
    And I should see a success message in the asset upload table for file upload
    When I go to the "object" "modify" page for "the saved pid"
    And I follow the link to view assets
    And I follow the link to view asset details
    And I attach the asset file "sample_pdf.pdf"
    And I click "#replace_file"
    Then I should see "Asset has been successfully uploaded."
    And an AIP should exist for the saved pid
    And the AIP for the saved pid should have "3" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid
    And the manifest for version "3" for the saved pid should be valid

  Scenario: Re-upload asset
    When I create an object and save the pid
    And I go to the "asset" "new" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "Upload 1 file"
    Then I should see "Asset has been successfully uploaded."
    And I should see a success message in the asset upload table for file upload
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid
    And I go to the "object" "modify" page for "the saved pid"
    And I follow the link to view assets
    And I click "#dri_delete_asset_file"
    And I accept the alert
    Then I should see a success message for asset deleted
    And an AIP should exist for the saved pid
    And the AIP for the saved pid should have "3" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid
    And the manifest for version "3" for the saved pid should be valid
    And I go to the "asset" "new" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "Upload 1 file"
    Then I should see "Asset has been successfully uploaded."
    And I should see a success message in the asset upload table for file upload
    And the AIP for the saved pid should have "4" versions
    And the manifest for version "4" for the saved pid should be valid

  Scenario: Mark object as reviewed
    When I create an object and save the pid
    And I go to the "object" "modify" page for "the saved pid"
    And I press the button to "update status"
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid

  Scenario: Delete an unpublished object
    When I create an object and save the pid
    And I go to the "object" "modify" page for "the saved pid"
    Then I should see a button to delete object with the saved pid
    When I follow the link to delete an object
    And I press the button to "delete object with the saved pid"
    Then I should see "Object has been deleted."
    Then an AIP should exist for the saved pid
    And the AIP for the saved pid should have "2" versions
    And the manifest for version "1" for the saved pid should be valid
    And the manifest for version "2" for the saved pid should be valid
