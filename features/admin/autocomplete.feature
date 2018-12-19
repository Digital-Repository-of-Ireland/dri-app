@javascript @stub_requests
Feature: Autocomplete
  In order to manage my Digital Objects
  As an authorized user
  I want to get autocomplete suggestions from appropriate controlled vocabularies
  When I use the coverages, places, temporal, or subjects text inputs

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And I am on the home page
  When I go to "create new collection"

# autocomplete dropdown is only visible when in use
Scenario: Seeing autocomplete vocab dropdown
  Then I should see 0 visible elements ".vocab-dropdown"
  When I press the edit collection button with text "Add Coverage"
  Then I should see 1 visible element ".vocab-dropdown"

Scenario: Seeing autocomplete results
  Then I should see 0 visible elements ".ui-autocomplete"
  When I press the edit collection button with text "Add Place"
  And I fill in "batch_geographical_coverage][" with "dublin"
  Then I should see 1 visible element ".ui-autocomplete"

Scenario: Choosing an autocomplete result
  When I press the edit collection button with text "Add Temporal Coverage"
  And I fill in "batch_temporal_coverage][" with "20th century"
  Then the text in "batch_temporal_coverage][" should not have link styling
  And I should see 1 visible element ".ui-autocomplete"
  And I click the first autocomplete result
  Then the text in "batch_temporal_coverage][" should have link styling

Scenario: Choosing an autocomplete result should save the label text and hidden URL of the subject
  When I press the edit collection button with text "Add Subject"
  And I fill in "batch_subject][" with "Dublin"
  And I click the first autocomplete result
  Then the hidden "batch_subject][" field within "fieldset#subject" should contain "http:\/\/example\.com\/"

Scenario: Choosing an autocomplete result, then changing your mind
  When I press the edit collection button with text "Add Subject"
  And I fill in "batch_subject][" with "Dublin"
  And I click the first autocomplete result
  Then the hidden "batch_subject][" field within "fieldset#subject" should contain "http:\/\/example\.com\/"
  And the text in "batch_subject][" should have link styling
  When I fill in "batch_subject][" with "asdf"
  # requires click on any other element to trigger on change
  And I press the edit collection button with text "Add Subject"
  Then I should not see a hidden "input#batch_subject][" within "fieldset#subject"
  Then the text in "batch_subject][" should not have link styling

Scenario: Submitting a collection with autocomplete results
  When I enter valid metadata for a collection
  And I "Add Coverage" and fill in "Ireland" and choose the first autocomplete result
  And I "Add Place" and fill in "Dublin" and choose the first autocomplete result
  And I "Add Temporal Coverage" and fill in "20th Century" and choose the first autocomplete result
  And I "Add Subject" and fill in "Leinster house" and choose the first autocomplete result
  And I check "deposit"
  And I press the button to "create a collection"
  Then I should see a success message for creating a collection
  When I follow the link to full metadata
  Then I should see "Ireland" within ".modal-body .dri_object_metadata_readview"
  And I should see "Dublin" within ".modal-body .dri_object_metadata_readview"
  And I should see "20th Century" within ".modal-body .dri_object_metadata_readview"
  And I should see "Leinster House" within ".modal-body .dri_object_metadata_readview"
  # the 4 hidden URIs for each autocomplete result, saved in the metadata
  And I should see 4 visible elements ".modal-body .dri_object_metadata_readview dd a"

Scenario: Disabling autocomplete
  When I press the edit collection button with text "Add Coverage"
  And I select "Disable" from the autocomplete menu
  And I fill in "batch[coverage][]" with "test"
  Then I should see 0 visible elements ".ui-autocomplete"

Scenario: Re-enabling autocomplete
  When I press the edit collection button with text "Add Coverage"
  And I select "Disable" from the autocomplete menu
  And I fill in "batch[coverage][]" with "test"
  Then I should see 0 visible elements ".ui-autocomplete"
  When I select "NUTS3" from the autocomplete menu
  And I fill in "batch[coverage][]" with "dublin"
  Then I should see 1 visible elements ".ui-autocomplete"
