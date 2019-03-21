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
  When I fill in "title" with "*Two" within "#advanced_search"
  And I fill in "creator" with "*Two" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 1 collection with title "titleTwo"

Scenario: Boolean OR search
  When I fill in "title" with "*Two" within "#advanced_search"
  And I fill in "creator" with "*Two" within "#advanced_search"
  And I select "any" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 2 collections with titles "titleTwo, titleThree"

Scenario: Wildcard search
  When I fill in "title" with "*e*e*" within "#advanced_search"
  # creator and op lines should not be necessary but spec fails in headless chrome without them
  # related to https://github.com/Codeception/CodeceptJS/issues/561 ?
  When I fill in "creator" with "*" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 2 collections with titles "titleOne, titleThree"

Scenario: Single character query
  Given a collection with pid "tZ" and title "Z" created by "userZ"
  And the collection with pid "tZ" is published
  When I fill in "title" with "Z" within "#advanced_search"
  And I fill in "creator" with "*" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  Then I should see 1 collection with title "Z"
