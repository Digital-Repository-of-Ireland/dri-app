@bug
Feature: Bug-395

Scenario: Search Fields drop-down should appear on the ingest page
  Given I am logged in as "user1"
  When I go to "ingest an object"
  Then I should see a selectbox for "search_field"

Scenario: Search Fields drop-down should appear on the collection page
  Given I am logged in as "user1"
  When I go to "my collections page"
  Then I should see a selectbox for "search_field"
