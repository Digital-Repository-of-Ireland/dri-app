@cookies @javascript
Feature: Advanced Search
  As an new visitor to the DRI
  I should be able to run advanced / boolean searches

Background:
  Given a collection with pid "t1" and title "titleOne" created by "userOne"
  And a collection with pid "t2" and title "titleTwo" created by "userTwo"
  And a collection with pid "t3" and title "titleThree" created by "userTwo"
  # catch false positive, Two in only one field
  And the collection with pid "t1" is published
  And the collection with pid "t2" is published
  And the collection with pid "t3" is published
  And I am not logged in
  And I go to "the advanced search page"
  And I accept cookies terms

Scenario: Boolean AND search
  When I fill in "Title" with "*Two" within "#advanced_search"
  And I fill in "Creator" with "*Two" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 1 collection with title "titleTwo"

Scenario: Boolean OR search
  When I fill in "Title" with "*Two" within "#advanced_search"
  And I fill in "Creator" with "*Two" within "#advanced_search"
  And I select "any" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 2 collections with titles "titleTwo, titleThree"

Scenario: Boolean NOT search
  When I fill in "Title" with "-*Two" within "#advanced_search"
  When I fill in "Creator" with "*" within "#advanced_search"
  And I select "any" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 2 collections with titles "titleOne, titleThree"

Scenario: Wildcard search
  When I fill in "Title" with "*e*e*" within "#advanced_search"
  # creator and .query-criteria#op lines should not be necessary but spec fails in headless chrome without them
  # related to https://github.com/Codeception/CodeceptJS/issues/561 ?
  When I fill in "Creator" with "*" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 2 collections with titles "titleOne, titleThree"

Scenario: Single character query
  Given a collection with pid "tZ" and title "Z" created by "userZ"
  And the collection with pid "tZ" is published
  When I fill in "Title" with "Z" within "#advanced_search"
  And I fill in "Creator" with "*" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 1 collection with title "Z"

Scenario: Browse tabs should not reload the page
  When I fill in "Title" with "test tabs" within "#advanced_search"
  And I press "#dri_browse_sort_tabs_objects_id_no_reload"
  And I press "#dri_browse_sort_tabs_collections_id_no_reload"
  Then I should see an input "title" with text "test tabs" within "#advanced_search"

Scenario Outline: "<TEST_STRING>" dropdowns should not reload the page
  When I fill in "Title" with "test <TEST_STRING>" within "#advanced_search"
  And I select "<SELECTION>" from "<SELECTOR>"
  Then I should see an input "title" with text "test <TEST_STRING>" within "#advanced_search"
  Examples:
    | SELECTOR        | SELECTION | TEST_STRING  |
    | select#sort     | Title     | sorting      |
    | select#per_page | 18        | pagination   |

Scenario: Browse settings should be preserved between simple and advanced search
  Given I am on the home page
  And I click "#dri_browse_sort_tabs_objects_id"
  And I click "#advanced_search"
  Then I should see 1 visible element "#dri_browse_sort_tabs_objects_id_no_reload .selected"

Scenario: Browse settings should be preserved between advanced searches
  When I select "any" from ".query-criteria #op"
  And I press "#dri_browse_sort_tabs_sub_collections_id_no_reload"
  And I fill in "Title" with "titleOne" within "#advanced_search"
  And I select "t1" in facet "Collection" with id "blacklight-root_collection_id_sim"
  And I select "Relevance" from "select#sort"
  And I select "36" from "select#per_page"
  # submit search and check search settings are displayed correctly
  When I press "#advanced-search-submit"
  Then I should be on the catalog page
  And I should see "t1" in facet with id "blacklight-root_collection_id_sim"
  And I should see 1 visible element "#dri_browse_sort_tabs_collections_id .selected"
  And I should see 1 visible element "#dri_browse_sort_tabs_sub_collections_id .selected"
  And I should see "Relevance" selected in "sort"
  And I should see "36 Results" selected in "per_page"
  # go back to advanced search and check the settings are preserved
  When I press "#advanced_search"
  Then I should be on the advanced search page
  And I should see "any" selected in "op"
  And I should see 1 visible element "#dri_browse_sort_tabs_collections_id_no_reload .selected"
  And I should see 1 visible element "#dri_browse_sort_tabs_sub_collections_id_no_reload .selected"
  And I should see an input "title" with text "titleOne" within "#advanced_search"
  And I should see 1 visible element "#facet-root_collection_id_sim.in"
  And I should see "Relevance" selected in "sort"
  And I should see "36 Results" selected in "per_page"

Scenario: Faceted Search for a normal end-user (anonymous or registered)
  Given I am on the advanced search page with mode = collections
  And I select "t1" in facet "Collection" with id "blacklight-root_collection_id_sim"
  And I press "#advanced-search-submit"
  Then I should see a search result "titleOne"
  And I should see "t1" in facet with id "blacklight-root_collection_id_sim"

Scenario: Resetting all search terms
  Given I am on the advanced search page
  When I select "t1" in facet "Collection" with id "blacklight-root_collection_id_sim"
  And I fill in "Title" with "*Two" within "#advanced_search"
  And I fill in "Creator" with "*Two" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 1 visible element "#browse_clear_all"
  And I should see "t1" in the facet well
  And I should see "Titles = *Two" in the facet well
  And I should see "Creators = *Two" in the facet well
  When I click "#browse_clear_all"
  And I should not see "t1" in the facet well
  And I should not see "Titles = *Two" in the facet well
  And I should not see "Creators = *Two" in the facet well
