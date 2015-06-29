Feature: Export files

DELETEME: REQ-37
DELETEME:
DELETEME: The system shall allow users to export files to their local drive in accordance with their access rights and the object's access rights.
DELETEME:
DELETEME: 1.1 It shall allow the user to export files and data using user selected formats provided by DRI
DELETEME: 1.2 It shall alert the user to any copyright and reuse restrictions.
DELETEME: 1.3 It shall display a to the user a user license agreement.

In order to export the Digital Objects metadata and asset
As an authenticated and authorised user
I want to be able to download the metadata in a user selected format
And the asset file to my local drive

Background:
  Given I am logged in as "user1"
  Given a Digital Object with pid "1234", title "Object 1" created by "user1"
  And a collection with pid "coll1" created by "user1@user1.com"
  When I add the Digital Object "1234" to the collection "coll1" as type "governing"
  And I go to the "object" "show" page for "1234"
  And I add the asset "sample_audio.mp3" to "1234"
  And the object with pid "coll1" has status published
  And the object with pid "1234" has status published
  Then the collection "coll1" should contain the Digital Object "1234" as type "governing"
  Given I am not logged in


Scenario: Export DigitalObject's metadata
  When I go to the "object" "show" page for "1234"
  Then I should see a "rights statement"
  #And I should see a "licence"
  And I should see a link to download metadata

Scenario: Export a DigitalObject's asset
  Given PENDING: UI work, should public head be able to export data - see policy/usage etc...
  When I go to the "object" "show" page for "1234"
  Then I should see a "rights statement"
  #And I should see a "licence"
  And I should see a link to download asset
