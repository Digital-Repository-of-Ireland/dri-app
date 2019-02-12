@cookies @javascript
Feature: Subcollections
  As an new visitor to the DRI
  I should be able to search DRI for public collections / subcollections / objects

Background:
  Given a collection with pid "collection1" and title "TCD" created by "admin"
  And the collection with pid "collection1" is published
  And I am not logged in
  And I go to "the home page"
  And I accept cookies terms

Scenario: Successful search using All Fields
  When I select "All Fields" from "#search_field"
  And I fill in "q" with "TCD"
  And I perform a search
  And I select the "collections" tab
  Then I should see a search result "TCD"
