@javascript
Feature: Collection Manager Tools
  As a collection manager
  I should have appropriate tools for managing collections

Background:
  Given I am logged in as "user1" in the group "cm"
  And a collection with pid "col1" created by "user1"

# Bug 1833
# Button not actually disabled, just doesn't open model. Solves issue with tooltip.
# See app/views/my_collections/_show_collection_manager_tools.html.erb for more details
Scenario: Publish disabled when collection has no reviewed objects or depositing organistaion
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should see a popover with the title "Publish not available"
  When I click "button#publish"
  Then I should not see a modal

Scenario: Publish disabled when collection has no reviewed objects
  Given I have associated the institute "TestInstitute" with the collection with pid "col1"
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should see a popover with the title "Publish not available"
  When I click "button#publish"
  Then I should not see a modal

Scenario: Publish disabled when collection has no depositing organistaion
  Given a Digital Object with pid "object1" and title "Object1" in collection "col1"
  And the object with pid "object1" is reviewed
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should see a popover with the title "Publish not available"
  When I click "button#publish"
  Then I should not see a modal

Scenario: Publish enabled when collection has reviewed objects and a depositing organisation
  Given a Digital Object with pid "object1" and title "Object1" in collection "col1"
  And the object with pid "object1" is reviewed
  And I have associated the institute "TestInstitute" with the collection with pid "col1"
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  When I click "button#publish"
  Then I should see a modal with title "Publish Reviewed"

Scenario: Publish enabled when collection has reviewed subcollection and a depositing organisation
  Given a collection with pid "sub_col1" and title "Subcollection" created by "user1"
  And the collection with pid "sub_col1" is in the collection with pid "col1"
  And a Digital Object with pid "object1" and title "Object1" in collection "sub_col1"
  And the object with pid "object1" is reviewed
  And the collection with pid "sub_col1" is reviewed
  And I have associated the institute "TestInstitute" with the collection with pid "col1"
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should not see a popover
  When I click "button#publish"
  Then I should see a modal with title "Publish Reviewed"
