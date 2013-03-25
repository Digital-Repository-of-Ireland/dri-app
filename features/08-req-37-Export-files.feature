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
  Given a Digital Object with pid "dri:obj1" and title "Object 1"
  And a collection with pid "dri:coll1"
  When I add the Digital Object "dri:obj1" to the collection "dri:coll1" as type "governing"
  Then the collection "dri:coll1" should contain the Digital Object "dri:obj1" as type "governing"

Scenario: Export DigitalObject's metadata
  When I go to the "object" show page for "dri:obj1"
  Then I should see a "rights statement"
  And I should see a "license"
  And I should see a link to metadata
  

#Scenario: Export DigitalObject metadata in a user selected format

Scenario: Export a DigitalObject's asset
  When I go to the "object" show page for "dri:obj1"
  Then I should see a "rights statement"
  And I should see a "license"
  And I should see a link to asset
