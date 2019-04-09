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

# TODO: move to browse-mode.feature ?
Scenario: Browse tabs should not reload the page
  When I fill in "Title" with "test tabs" within "#advanced_search"
  And I press "#dri_browse_sort_tabs_objects_id_no_reload"
  And I press "#dri_browse_sort_tabs_collections_id_no_reload"
  Then I should see an input "title" with text "test tabs" within "#advanced_search"

Scenario: Browse tabs should be the same on the results page
  When I fill in "Title" with "test tabs" within "#advanced_search"
  And I press "#dri_browse_sort_tabs_sub_collections_id_no_reload"
  And I press "#advanced-search-submit"
  Then I should see 1 visible element "#dri_browse_sort_tabs_collections_id .selected"
  And I should see 1 visible element "#dri_browse_sort_tabs_sub_collections_id .selected"

Scenario Outline: "<TEST_STRING>" dropdowns should not reload the page
  When I fill in "Title" with "test <TEST_STRING>" within "#advanced_search"
  And I select "<SELECTION>" from "<SELECTOR>"
  Then I should see an input "title" with text "test <TEST_STRING>" within "#advanced_search"
  Examples:
    | SELECTOR        | SELECTION | TEST_STRING  |
    | select#sort     | Title     | sorting      |
    | select#per_page | 18        | pagination   |

# TODO test on catalog page and click button to go to adv. search
Scenario: Browse tabs should change base on url params
  Given I am on the advanced search page with mode = sub_collections
  Then I should see 1 visible element "#dri_browse_sort_tabs_collections_id_no_reload .selected"
  And I should see 1 visible element "#dri_browse_sort_tabs_sub_collections_id_no_reload .selected"

Scenario Outline: "<PARAM>" dropdowns should change based on url params
  Given I am on the advanced search page with <PARAM> = <PARAM_VALUE>
  Then "<LABEL>" should be selected in "<PARAM>"
  Examples:
    | PARAM     | PARAM_VALUE                                     | LABEL        |
    | sort      | title_sorted_ssi asc, system_create_dtsi desc   | Title        |
    | per_page  | 36                                              | 36 Results   |

Scenario: Browse tab defaults to collections
  Given I am on the advanced search page
  Then I should see 1 visible element "#dri_browse_sort_tabs_collections_id_no_reload .selected"

# Scenario: Changing tab should load the facets for that type
#   Given I am on the advanced search page
#   And I press "#dri_browse_sort_tabs_objects_id_no_reload"
#   # Then I should see the object facets
#   When I press "#dri_browse_sort_tabs_objects_id_no_reload"
#   # Then I should see the collection facets

Scenario Outline: Faceted Search for a normal end-user (anonymous or registered)
  # Given the collection with pid "t1" has "<ATTRIBUTE>" = "<SEARCH>"
  # TODO: reload facets via ajax
  # DRI::QualifiedDublinCore.where(is_collection_tesim: "true").map(&:subject)
  Given I am on the advanced search page with mode = collections
  # And I search for "<SEARCH>" in facet "<FACETNAME>" with id "<FACETID>"
  And I select "<SEARCH>" in facet "<FACETNAME>" with id "<FACETID>"
  And I press "#advanced-search-submit"
  Then I should see a search result "<RESULT>"
  And I should see "<SEARCH>" in facet with id "<FACETID>"

  Examples:
    | FACETNAME  | FACETID                              | SEARCH       | RESULT             |
    | Collection | blacklight-root_collection_id_sim    | t1           | titleOne           |
    # | Places     | blacklight-placename_field_sim       | sample country  | SAMPLE AUDIO TITLE |
    # | Names      | blacklight-person_sim                | collins         | SAMPLE AUDIO TITLE |

    # | FACETNAME  | FACETID                              | SEARCH           | ATTRIBUTE | RESULT             |
    # | Language   | blacklight-language_sim              | eng              | language  | t1                 |
    # | Subjects   | blacklight-subject_sim               | advanced_subject | subject   | SAMPLE AUDIO TITLE |
