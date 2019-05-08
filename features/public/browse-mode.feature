@cookies @javascript
Feature: Browse Mode
  As an new visitor to the DRI
  I should be able to browse Collections, Sub-Collections and objects in the catalog

Background:
  Given I am logged in as "user1" in the group "cm"
  And a collection with pid "col1" and title "Parent" created by "user1"
  And a collection with pid "sub_col1" and title "Child" created by "user1"

  And a Digital Object with pid "obj1ect1" and title "Object1" in collection "col1"
  And a Digital Object with pid "object2" and title "Object2" in collection "sub_col1"
  
  And the collection with pid "sub_col1" is in the collection with pid "col1"
  And the collection with pid "col1" is published

  And I am on the show Digital Object page for id col1
  And I click "#collection_s_object"

# Collections tab show collections only
# Sub-Collections tab shows collections and subcollections (selects both tabs too)
# Objects tab selects object only
Scenario: Browse tabs highlighting
  Then I should see 0 visible element "#collections.selected"
  Then I should see 0 visible element "#sub_collections.selected"
  Then I should see 1 visible element "#objects.selected"

  When I click "#sub_collections"
  Then I should see 1 visible element "#collections.selected"
  Then I should see 1 visible element "#sub_collections.selected"
  Then I should see 0 visible element "#objects.selected"

  When I click "#collections"
  Then I should see 1 visible element "#collections.selected"
  Then I should see 0 visible element "#sub_collections.selected"
  Then I should see 0 visible element "#objects.selected"

Scenario: Browse for objects
  When I click "#objects"
  Then I should see 1 visible elements ".dri_content_block"
  And I should see 0 visible element ".dri_content_block_collection"
  And all ".dri_content_block" within "#dri_result_container_id" should link to an object

Scenario: Browse for subcollections
  When I click "#sub_collections"
  Then I should see 0 visible elements ".dri_content_block"
  And I should see 2 visible element ".dri_content_block_collection"
  And all ".dri_content_block_collection" within "#dri_result_container_id" should link to a collection

Scenario: Browse for collections
  When I click "#collections"
  Then I should see 0 visible elements ".dri_content_block"
  And I should see 1 visible element ".dri_content_block_collection"
  And all ".dri_content_block_collection" within "#dri_result_container_id" should link to a root collection
