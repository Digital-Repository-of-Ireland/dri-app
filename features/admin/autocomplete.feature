@javascript
Feature: Autocomplete
  In order to manage my Digital Objects
  As an authorized user
  I want to get autocomplete suggestions from appropriate controlled vocabularies
  When I use the coverages, places, temporal, or subjects text inputs

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

Scenario: See autocomplete vocab dropdown
  Given I am on the home page
  When I go to "create new collection"
  Then I should see 0 visible elements ".vocab-dropdown"
  # And I enter valid metadata for a collection
  And I press the edit collection button with text "Add Coverage"
  Then I should see 1 visible element ".vocab-dropdown"

Scenario: See autocomplete results
  Given I am on the home page
  When I go to "create new collection"
  Then I should see 0 visible elements ".ui-autocomplete"
  And I press the edit collection button with text "Add Place"
  And I fill in "batch_geographical_coverage][" with "dublin"
  Then I should wait for "1" seconds
  And I should see 1 visible element ".ui-autocomplete"

Scenario: Choosing an autocomplete result should apply link style to the text in the input
  Given I am on the home page
  When I go to "create new collection"
  And I press the edit collection button with text "Add Temporal Coverage"
  And I fill in "batch_temporal_coverage][" with "20th century"
  Then the text in "batch_temporal_coverage][" should not have link styling
  Then I should wait for "1" seconds
  And I should see 1 visible element ".ui-autocomplete"
  And I click the first autocomplete result
  Then the text in "batch_temporal_coverage][" should have link styling

Scenario: Choosing an autocomplete result should save the label text and URL of the subject
  Given I am on the home page
  When I go to "create new collection"
  And I press the edit collection button with text "Add Subject"
  And I fill in "batch_subject][" with "Dublin"
  Then I should wait for "1" seconds
  And I click the first autocomplete result
  Then the hidden "batch_subject][" field within "fieldset#subject" should contain "http:\/\/id\.loc\.gov\/authorities\/subjects\/"
