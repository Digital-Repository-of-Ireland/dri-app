@cookies @javascript
Feature: Search
  As an new visitor to the DRI
  I should be able to search DRI for public collections / subcollections / objects

Background:
  Given I am not logged in
  And I go to "the home page"

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

  # Cucumber doesn't support nested scenario outlines
  # Have to use a home (catalog) and my collections example for each field
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

Scenario Outline: Successful search for name with orcid in "Names"
  Given I am on the home page
  Given a collection with pid "collection1"
  And the collection with pid "collection1" has "contributor" = "name=Stephenson, Stephen; authority=ORCID; identifier=https://orcid.org/1111-2222-3333-4444"
  And the collection with pid "collection1" has "creator" = "Paulson, Paul"
  And the collection with pid "collection1" is published
  When I select "Names" from "#search_field"
  And I fill in "q" within "#searchform" with:
    """
    "<query>"
    """
  And I perform a search
  And I select the "collections" tab
  Then I should see a search result "<query>"
  And I should see 1 visible element ".dri_content_block_collection"

  Examples:
    | query               |
    | Paulson, Paul       |
    | Paul Paulson        |
    | Stephenson, Stephen |
    | Stephen Stephenson  |

Scenario: Advanced Search Link
  When I press "#advanced_search_button"
  Then I should see a modal with title "Advanced Search"

Scenario: Reset Search
  Given I am on the home page
  Then I should see 0 visible elements "#browse_clear_all"
  When I fill in "q" with "test"
  And I perform a search
  Then I should see 1 visible element "#browse_clear_all"
  When I click "#browse_clear_all"
  Then I should see 0 visible elements "#browse_clear_all"

#TODO fix single character queries (will there ever be collections / objects with a single character field in prod?)
