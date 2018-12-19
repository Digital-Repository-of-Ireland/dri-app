@collections @req-17 @done @req-61 @req-63 @javascript
Feature: Collections
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to add my Digital Objects to a collection
  And to retrieve my Digital Objects by collection

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

@wip
Scenario: Navigating to the collections page
  Given I am on the home page
  Then I should see a link to browse
  When I follow the link to browse
  Then I should see a link to collections
  When I follow the link to collections
  Then I should be on the collections page

Scenario: Constructing a valid collection
  Given I am on the home page
  When I go to "create new collection"
  And I enter valid metadata for a collection
  And I check "deposit"
  And I press the button to "create a collection"
  Then I should see a success message for creating a collection

Scenario: Constructing a collection with valid permissions
  Given I am on the home page
  When I go to "create new collection"
  And I enter valid metadata for a collection
  And I enter valid permissions for a collection
  And I check "deposit"
  And I press the button to "create a collection"
  Then I should see a success message for creating a collection

Scenario: Constructing a collection with invalid permissions
  Given I am on the home page
  When I go to "create new collection"
  And I enter valid metadata for a collection
  And I enter invalid permissions for a collection
  And I check "deposit"
  And I press the button to "create a collection"
  Then I should see a failure message for invalid collection

Scenario: Constructing a collection (form focus)
  Given I am on the home page
  When I go to "create new collection"
  Then the element with id "batch_title][" should be focused

Scenario: Updating a collection (description form focus)
  Given a collection with pid "collperm" created by "user1"
  When I go to the "collection" "edit" page for "collperm"
  And I press the edit collection button with text "Add Description"
  Then the element with id "batch_description][" should be focused

Scenario: Updating a collection (creators form focus)
  Given a collection with pid "collperm" created by "user1"
  When I go to the "collection" "edit" page for "collperm"
  And I press the edit collection button with text "Add Creator"
  Then the element with id "batch_creator][" should be focused

Scenario: Updating a collection with invalid metadata
  Given a collection with pid "collperm" created by "user1"
  When I go to the "collection" "edit" page for "collperm"
  And I enter invalid metadata for a collection
  And I press the button to "save collection changes"
  Then I should not see a success message for updating a collection

Scenario Outline: Adding a Digital Object in a governing collection
  Given a Digital Object with pid "<object_pid>", title "<object_title>", description "<object_desc>", type "<object_type>" and rights "<object_rights>"
  And a collection with pid "<collection_pid>"
  When I add the Digital Object "<object_pid>" to the collection "<collection_pid>" as type "<governance_type>"
  Then the collection "<collection_pid>" should contain the Digital Object "<object_pid>" as type "<governance_type>"

  Examples:
    | object_pid | object_title | object_desc | object_type | object_rights | collection_pid | governance_type |
    | object1   | Object 1     | Test 1      | Sound       | Test Rights   | coll1      | governing       |
    | object2   | Object 2     | Test 2      | Text        | Test Rights   | coll1      | governing       |

Scenario: Creating Digital Object in a governing collection using the web forms
  Given a collection with pid "coll2" created by "user1"
  When I go to the "metadata" "upload" page for "coll2"
  And I attach the metadata file "valid_metadata.xml"
  And I press the button to "ingest metadata"
  Then the collection "coll2" should contain the new digital object

Scenario: Deleting a collection as an admin
  Given I am not logged in
  Given I am logged in as "admin" in the group "admin" and accept cookies
  Given a collection with pid "coll6" created by "user1@user1.com"
  And the collection with pid "coll6" has status published
  When I go to the "my collections" "show" page for "coll6"
  Then I should see a button to delete collection with id coll6
  When I follow the link to delete a collection
  And I press the button to "delete collection with id coll6"
  And I accept the alert
  Then I should see a success message for deleting a collection

Scenario: Non-admin should not be given option to delete
  Given a collection with pid "collec7" created by "user1"
  And the collection with pid "collec7" has status published
  When I go to the "my collections" "show" page for "collec7"
  And I click the link to edit a collection
  Then I should not see a link to delete a collection

Scenario: Committing a Digital Object which is a duplicate of an existing Digital Object in the same collection
#  Given a Digital Object with pid "dri:obj6" and title "Object 6"
#  And a collection with pid "dri:coll6"
#  And the collection "dri:coll6" already contains the Digital Object "dri:obj6"
#  When I commit the Digital Object
#  Then I should get a duplicate object warning
#  And I should be given a choice of using the existing object or creating a new one

@wip
Scenario: Using the new design to create a collection
  Given I am on the home page
  Then I should see a link to collections
  When I hover over the link to collections
  Then I should see the collection sub-menu
  When I follow the link to add a new collection
  Then I should see the select collection type form
  When I enter a collection title
  And I select a metadta type
  And I press the button to Continue
  Then I should see the add your collection details form
  When I upload a cover image
  And I enter a description
  And I enter a creation date
  And I select the default copyright holder
  And I press select the desired licence
  And I press the button to download the Deposit Agreement
  And I sign the Deposit Agreement
  And I upload the signed Deposit Agreement
  And I tick the box to agree to the terms and conditions of the Deposit Agreement
  And I select the default language
  And I add read access group public
  And I select an Institutional Entity from the dropdown list
  And I press the button to add the existing Institutional Entity
  And I upload a logo for a new Institutional Entity
  And I enter a name for the new Institutional Entity
  And I enter a url for the new Institutional Entity
  And I press the button to add the new institutional Entity
  And I select read only access for public users
  And I give public users search access
  And I give public users export access
  And I press the button to save draft
  Then my collection should be created

@wip @noexec
Scenario: user requests access to readers group for restricted asset
  Given I am not logged in
  Given I am logged in as "admin" in the group "admin"
  And I have created a collection with title "Restricted Collection"
  And I have created a "Sound" object with title "Restricted Object" in the collection "Restricted Collection"
  And the collection with title "Restricted Collection" has status published
  And the object with title "Restricted Object" has status published
  And I have added an audio file
  And the masterfile for object with title "Restricted Object" is "accessible"
  And the object with title "Restricted Object" is restricted to the reader group
  And I am not logged in
  And I am logged in as "user1"
  And I am on the home page
  When I perform a search
  And I press "Restricted Object"
  And I press the button to request access
  Then I should see a message for application pending
  And I should not see a link to download asset
  Given I am not logged in
  And I am logged in as "admin"
  And I am on the my collections page
  And I press "Restricted Collection"
  Then I should see "user1@user1.com"
  And I should see a button to approve membership request
  When I press the button to approve membership request
  Then I should see a message for membership approved
  Given I am not logged in
  And I am logged in as "user1"
  And I am on the home page
  When I perform a search
  And I press "Restricted Object"
  Then I should see a link to download asset
