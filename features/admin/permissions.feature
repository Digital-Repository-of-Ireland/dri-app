@permissions @javascript
Feature:
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to set permissions on my Digital Objects
  And to retrieve my Digital Objects by collection

@wip @disabled-pilot
Scenario: Setting a list of users for restricted access
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And I am on the home page
  When I press the button to ingestion
  And I press the button to add new collection
  And I enter valid metadata for a collection
  And I choose "batch_read_groups_string_radio_restricted"
  And I fill in "batch_read_users_string" with "test, test2, test3"
  And I press the button to create a collection
  Then I should see a success message for creating a collection
  When I follow the link to edit a collection
  Then the "batch_read_users_string" field should contain "test, test2, test3"

Scenario: Constructing a Collection using the web form should set default permissions
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And I am on the home page
  And I follow the link to ingest page
  And I press the button to add new collection
  And the radio button "batch_read_groups_string_radio_public" should be "checked"
  And the "batch_manager_users_string" field should contain "user1@user1.com"

Scenario Outline: Constructing a Digital Object using the web form should set default permissions
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And I have created a collection
  And I am on the new Digital Object page
  When I select a collection
  And I press the button to continue
  And I select "input" from the selectbox for ingest methods
  And I press the button to continue
  When I enter valid "<object_type>" metadata
  And I press the button to continue
  Then I should see a success message for ingestion
  When I follow the link to edit an object
  And the radio button "batch_read_groups_string_radio_inherit" should be "checked"
  And the radio button "batch_edit_groups_string_radio_inherit" should be "checked"

  Examples:
    | object_type |
    | Text        |
    | Sound       |

Scenario Outline: Constructing a Digital Object using XML upload should set default permissions
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And I have created a collection
  And I am on the new Digital Object page
  When I select a collection
  And I press the button to continue
  And I select "upload" from the selectbox for ingest methods
  And I press the button to continue
  And I attach the metadata file "<metadata_file>"
  And I press the button to ingest metadata
  Then I should see a success message for ingestion
  When I follow the link to edit an object
  And the hidden "batch_read_groups_string" field should contain ""

  Examples:
    | metadata_file                 |
    | dublin_core_pdfdoc_sample.xml |
    | SAMPLEA.xml                   |

Scenario Outline: Collection visibility
  Given a collection with pid "dri:coll8" and title "Access Test" created by "test@test.com"
  Given I am not logged in
  Given I am logged in as "user2" and accept cookies
  And I am on the new Digital Object page
  Then the "ingest collection" drop-down should not contain the option "dri:coll8"
  When "user2@user2.com" has been granted "<permission>" permissions on "dri:coll8"
  And I am on the new Digital Object page
  Then the "ingest collection" drop-down should contain the option "dri:coll8"

  Examples:
    | permission |
    | edit       |
    | manage     |
