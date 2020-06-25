@permissions @javascript
Feature: Permissions
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to set permissions on my Digital Objects
  And to retrieve my Digital Objects by collection

Background:
  Given I am logged in as "user1" in the group "cm"

  #Scenario: Constructing a Collection using the web form should set default permissions
  #Given I am on the home page
  #And I go to "create new collection"
  #And the radio button "batch_read_groups_string_radio_public" should be "checked"
  #And the "batch_manager_users_string" field should contain "user1@user1.com"

Scenario: Constructing a Digital Object using the web form should set default permissions
  Given a collection with pid "perm1" created by "user1"
  When I go to the "collection" "new object" page for "perm1"
  When I enter valid "sound" metadata
  And I press the button to "continue"
  Then I should see a success message for ingestion
  When I follow the link to edit access controls
  And the radio button "batch_master_file_access_inherit" should be "checked"

Scenario: Constructing a Digital Object using XML upload should set default permissions
  Given a collection with pid "perm2" created by "user1"
  When I go to the "metadata" "upload" page for "perm2"
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  When I follow the link to edit access controls
  Then the radio button "batch_master_file_access_inherit" should be "checked"
