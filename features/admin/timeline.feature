@javascript
Feature: Viewing objects on the timeline
  As a user browsing the repository
  I should be able to view objects with valid dates on a timeline

  Background:
    Given I am logged in as "user1" in the group "cm"
    And a collection with title "Timeline Collection" created by "user1"

  @random_pid
  Scenario: View objects with dates
    Given I have created an object with metadata "metadata_timeline_date.xml" in the collection
    And I am on the my collections page
    And I select the "objects" tab
    And I follow the link to view the timeline
    Then I should see a section with id "dri_timeline_id"
    And I should see a selectbox for "dri_tlfield_options_id"
    And I should see a search result "Timeline Object"

  @random_pid
  Scenario: Should not view objects without valid dates
    Given I have created an object with metadata "metadata_no_timeline_date.xml" in the collection
    And I am on the my collections page
    And I select the "objects" tab
    And I follow the link to view the timeline
    Then I should see "No objects compatible with timeline display found"
