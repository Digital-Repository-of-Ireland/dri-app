@permissions @javascript
Feature:
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to set permissions on my Digital Objects
  And to retrieve my Digital Objects by collection

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

@wip @disabled-pilot
Scenario: Setting a list of users for restricted access
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And I am on the home page
  When I press the button to "ingestion"
  And I press the button to "add new collection"
  And I enter valid metadata for a collection
  And I choose "batch_read_groups_string_radio_restricted"
  And I fill in "batch_read_users_string" with "test, test2, test3"
  And I press the button to "create a collection"
  Then I should see a success message for creating a collection
  When I follow the link to edit a collection
  Then the "batch_read_users_string" field should contain "test, test2, test3"

Scenario: Constructing a Collection using the web form should set default permissions
  Given I am on the home page
  And I go to "create new collection"
  And the radio button "batch_read_groups_string_radio_public" should be "checked"
  And the "batch_manager_users_string" field should contain "user1@user1.com"

Scenario Outline: Constructing a Digital Object using the web form should set default permissions
  Given a collection with pid "perm1" created by "user1"
  When I go to the "collection" "show" page for "perm1"
  And I follow the link to add an object
  When I enter valid "<object_type>" metadata
  And I press the button to "continue"
  Then I should see a success message for ingestion
  When I follow the link to edit access controls
  And the radio button "batch_read_groups_string_radio_inherit" should be "checked"
  And the radio button "batch_edit_users_string_radio_inherit" should be "checked"

  Examples:
    | object_type |
    | Text        |
    | Sound       |

Scenario Outline: Constructing a Digital Object using XML upload should set default permissions
  Given a collection with pid "perm2" created by "user1"
  When I go to the "metadata" "upload" page for "perm2"
  And I attach the metadata file "<metadata_file>"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  When I follow the link to edit access controls
  Then the hidden "batch_read_groups_string" field should contain ""

  Examples:
    | metadata_file                 |
    | dublin_core_pdfdoc_sample.xml |
    | SAMPLEA.xml                   |

@wip
Scenario Outline: Collection visibility
  Given a collection with pid "coll8" and title "Access Test" created by "test"
  Given I am not logged in
  Given I am logged in as "user2" and accept cookies
  And I am on the new Digital Object page
  Then the "ingest collection" drop-down should not contain the option "coll8"
  When "user2@user2.com" has been granted "<permission>" permissions on "coll8"
  And I am on the new Digital Object page
  Then the "ingest collection" drop-down should contain the option "coll8"

  Examples:
    | permission |
    | edit       |
    | manage     |
