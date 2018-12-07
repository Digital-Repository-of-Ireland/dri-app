@javascript
Feature: Autocomplete
  In order to manage my Digital Objects
  As an authorized user
  I want to get autocomplete suggestions from appropriate controlled vocabularies
  When I use free text inputs on forms

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

Scenario: See autocomplete vocab dropdown when creating a collection
  Given I am on the home page
  When I go to "create new collection"
  And I enter valid metadata for a collection
  And I press the edit collection button with text "Add Coverage"
  # And I should wait for "1" seconds
  Then I should see a visible element ".vocab-dropdown"
