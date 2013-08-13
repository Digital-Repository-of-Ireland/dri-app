@permissions
Feature:
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to set permissions on my Digital Objects
  And to retrieve my Digital Objects by collection

Background:
  Given I am logged in as "user1" in the group "cm"

Scenario: Setting a list of users for restricted access
  Given I am on the my collections page
  When I press the button to add new collection
  And I enter valid metadata for a collection
  And I choose "dri_model_collection_read_groups_string_radio_restricted"
  And I fill in "dri_model_collection_read_users_string" with "test, test2, test3" 
  And I press the button to create a collection
  Then I should see a success message for creating a collection
  When I follow the link to edit a collection
  Then the "dri_model_collection_read_users_string" field should contain "test, test2, test3"
