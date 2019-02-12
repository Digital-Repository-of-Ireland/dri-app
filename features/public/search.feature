@cookies @javascript
Feature: Subcollections
  As an new visitor to the DRI
  I should be able to search DRI for public collections / subcollections / objects

Background:
  Given I am not logged in
  And I go to "the home page"
  And I accept cookies terms

Scenario Outline: Successful search for "<query>" in "<search_field>"
  Given a collection with pid "collection1"
  And the collection with pid "collection1" has "<attribute>" = "<query>"
  And the collection with pid "collection1" is published

  # Catch false positives. This collection shouldn't be returned in search
  And a collection with pid "false_positive"
  And the collection with pid "false_positive" has "<attribute>" = "asdf"
  And the collection with pid "false_positive" is published

  When I select "<search_field>" from "#search_field"
  And I fill in "q" with "<query>"
  And I perform a search
  And I select the "collections" tab
  Then I should see a search result "<query>"
  And I should see 1 visible element ".dri_content_block_collection"

  Examples:
    | search_field | query               | attribute |
    | All Fields   | TestCD              | title     |
    | Title        | Test College Dublin | title     |
    | Person       | Fake user           | creator   |
    | Person       | Other user          | depositor |
    | Subject      | Fake Subject        | subject   |
