@req-37 @done
Feature: Export files

In order to export the Digital Objects metadata and asset
As an authenticated and authorised user
I want to be able to download the metadata
And the asset file to my local drive

Background:
  Given I am logged in as "user1"
  Given a Digital Object with pid "dri:obj1", title "Object 1" created by "user1@user1.com"
  And a collection with pid "dri:coll1"
  When I add the Digital Object "dri:obj1" to the collection "dri:coll1" as type "governing"
  And I add the asset "sample_audio.mp3" to "dri:obj1"
  Then the collection "dri:coll1" should contain the Digital Object "dri:obj1" as type "governing"

Scenario: Export DigitalObject's metadata when I have edit/manage permissions
  When I go to the "object" "show" page for "dri:obj1"
  Then I should see a "rights statement"
  #And I should see a "licence"
  And I should see a link to download metadata

Scenario: Export a DigitalObject's asset when I have edit/manage permissions
  When I go to the "object" "show" page for "dri:obj1"
  Then I should see a "rights statement"
  #And I should see a "licence"
  And I should see a link to download asset

