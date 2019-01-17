@cookies @javascript
Feature: Browse Mode
  As an new visitor to the DRI
  I should be able to browse Collections, Sub-Collections and objects in the catalog

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And a collection with pid "col1" and title "Parent" created by "user1"
  And a collection with pid "sub_col1" and title "Child" created by "user1"

  And a Digital Object with pid "obj1ect1" and title "Object1" in collection "col1"
  And a Digital Object with pid "object2" and title "Object2" in collection "sub_col1"
  
  And the collection with pid "sub_col1" is in the collection with pid "col1"
  And the collection with pid "col1" is published

# Collections tab show collections only
# Sub-Collections tab shows collections and subcollections (selects collections and sub-collections tab)
# Objects tab selects object only
Scenario: Browsing subcollections with tabs
  Given I am on the show Digital Object page for id col1
  When I click "#collection_s_object"
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
  
