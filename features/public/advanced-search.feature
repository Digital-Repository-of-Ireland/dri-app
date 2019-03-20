@cookies @javascript
Feature: Advanced Search
  As an new visitor to the DRI
  I should be able to run advanced / boolean searches

Background:
  Given a collection with pid "t1" and title "titleOne" created by "userOne"
  And the collection with pid "t1" is published
  Given a collection with pid "t2" and title "titleTwo" created by "userTwo"
  And the collection with pid "t2" is published
  # catch false pos, 2 in only one field
  Given a collection with pid "t3" and title "titleThree" created by "userTwo"
  And the collection with pid "t3" is published
  Given I am not logged in
  And I go to "the advanced search page"
  And I accept cookies terms

# TODO fix single char queries (query 2 returns everything)
Scenario: Boolean AND search
  When I fill in "title" with "*Two" within "#advanced_search"
  When I fill in "creator" with "*Two" within "#advanced_search"
  And I select "all" from ".query-criteria #op"
  And I press "#advanced-search-submit"
  And I should see 1 visible elements ".dri_content_block_collection"

# Scenario: Boolean OR search
