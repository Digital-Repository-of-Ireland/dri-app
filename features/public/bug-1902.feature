@bug @cookies @javascript
Feature: bug-1902

Background:
  Given I am not logged in
  And I go to "the home page"
  # need existing published collection for facets to display
  Given a collection with pid "collection1"
  And the collection with pid "collection1" is published

Scenario: Toggle search facets
  # page reload required to see collection / facets
  Given I am on the home page
  Then I should see 1 visible element "#facet-panel-collapse"
  When I click "#facets div.dri_head_title a"
  # wait for data-collapse animation
  And I wait for "1" second
  Then I should see 0 visible elements "#facet-panel-collapse"
  
