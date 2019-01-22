@javascript
Feature: Collection Manager Tools
  As a collection manager
  I should have appropriate tools for managing collections

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

# Bug 1833
Scenario: Publish disabled when collection has no reviewed objects or depositing organistaion
  Given a collection with pid "col1" created by "user1"
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should see a popover with the title "Publish not available"

Scenario: Publish disabled when collection has no depositing organistaion
  Given a collection with pid "col1" created by "user1"
  And I have associated the institute "TestInstitute" with the collection with pid "col1"
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should see a popover with the title "Publish not available"

Scenario: Publish enabled when collection has reviewed objects and a depositing organisation
  Given a collection with pid "col1" created by "user1"
  And a Digital Object with pid "object1" and title "Object1" in collection "col1"
  And the object with pid "object1" is reviewed
  
  And I have associated the institute "TestInstitute" with the collection with pid "col1"
  When I am on the my collections page for id col1
  And I hover over a visible "button#publish"
  Then I should not see a popover


#Scenario Outline: When I click the publish button
#  When a collection with pid "col1" and "<collection_state>" created by "user1"
#  And I hover over "#publish"
#  Then I should see a help popover
#
#  Examples:
#    | collection_state        |
#    | no reviewed objects     |
#    | no depositing institute |
