@wip
Feature: NUIG Users

Scenario: User Accessing Content
  Given I am an "academic" user
  When I search for "keyword"
  And I select "irish" for the search result to be in
  Then I get a list of the "content"
  And I am able to stream the "content"
  And I get shown a sample "citation" piece of text
  And I get shown a "license" for the "content"
