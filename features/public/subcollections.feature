@cookies @javascript
Feature: Subcollections
  As an new visitor to the DRI
  I should be able to interact with public subcollections

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And a collection with pid "col1" and title "Parent" created by "user1"
  And a collection with pid "sub_col1" and title "Child" created by "user1"
  And the collection with pid "sub_col1" is in the collection with pid "col1"
  And the collection with pid "col1" is published

# May not always be in footer section, could rename?
Scenario: Visiting a subcollection from the parent collection footer section
  Given I am on the show Digital Object page for id col1
  When I click the first ".dri_collection_image" within "#collection_children"
  Then I should be on the show Digital Object page for id sub_col1
