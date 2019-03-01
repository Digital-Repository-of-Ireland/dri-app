@cookies @javascript
Feature: Subcollections
  As an new visitor to the DRI
  I should be able to search DRI for public collections / subcollections / objects

Background:
  Given I am not logged in
  And I go to "the home page"
  And I accept cookies terms

Scenario Outline: Successful search for "<query>" in all_fields
  Given a collection with pid "collection1"
  And the collection with pid "collection1" has "<attribute>" = "<query>"
  And the collection with pid "collection1" is published

  # Catch false positives. This collection shouldn't be returned in search
  And a collection with pid "false_positive"
  # false match for query
  And the collection with pid "false_positive" has "<attribute>" = "asdf"
  And the collection with pid "false_positive" is published

  When I select "All Fields" from "#search_field"
  And I fill in "q" with "<query>"
  And I perform a search
  And I select the "collections" tab
  Then I should see a search result "<query>"
  And I should see 1 visible element ".dri_content_block_collection"

  Examples:
    | query               | attribute   |
    | TestCD              | title       |
    | Fake user           | creator     |
    | Other user          | contributor |
    | Fake Subject        | subject     |


Scenario Outline: Successful search for "<query>" in "<search_field>"
  Given I am on the <page> page
  Given a collection with pid "collection1"
  And the collection with pid "collection1" has "<attribute>" = "<query>"
  And the collection with pid "collection1" is published

  # Catch false positives. This collection shouldn't be returned in search
  And a collection with pid "false_positive"
  # false match for query (q param)
  And the collection with pid "false_positive" has "<attribute>" = "asdf"
  # false match for search_field (search_field param)
  And the collection with pid "false_positive" has "language" = "<query>"
  And the collection with pid "false_positive" is published

  When I select "<search_field>" from "#search_field"
  And I fill in "q" with "<query>"
  And I perform a search
  And I select the "collections" tab
  Then I should see a search result "<query>"
  And I should see 1 visible element ".dri_content_block_collection"

  # No nested scenario outlines, have to a home (catalog) and my collections example for each field 
  Examples:
    | search_field | query                | attribute               | page           |
    | Titles       | Test College Dublin  | title                   | home           |
    | Subjects     | Fake Subject         | subject                 | home           |
    | Names        | Fake user            | creator                 | home           |
    | Names        | Other user           | contributor             | home           |
    | Names        | Third Person         | publisher               | home           |
    | Places       | Dublin               | geographical_coverage   | home           |
    | Titles       | Test College Dublin  | title                   | my collections |
    | Subjects     | Fake Subject         | subject                 | my collections |
    | Names        | Fake user            | creator                 | my collections |
    | Names        | Other user           | contributor             | my collections |
    | Names        | Third Person         | publisher               | my collections |
    | Places       | Dublin               | geographical_coverage   | my collections |
