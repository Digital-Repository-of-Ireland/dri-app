@collections @req-17 @done @req-61 @req-63
Feature:
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to add my Digital Objects to a collection
  And to retrieve my Digital Objects by collection

Background:
  Given I am logged in as "user1" in the group "cm"

Scenario: Navigating to the collections page
  Given I am on the home page
  Then I should see a link to my collections
  When I follow the link to my collections
  Then I should be on the my collections page

Scenario: Constructing a valid collection
  Given I am on the my collections page
  When I press the button to add new collection
  And I enter valid metadata for a collection
  And I press the button to create a collection
  Then I should see a success message for creating a collection

Scenario: Constructing a collection with valid permissions
  Given I am on the my collections page
  When I press the button to add new collection
  And I enter valid metadata for a collection
  And I enter valid permissions for a collection
  And I press the button to create a collection
  Then I should see a success message for creating a collection

Scenario: Constructing a collection with invalid permissions
  Given I am on the my collections page
  When I press the button to add new collection
  And I enter valid metadata for a collection
  And I enter invalid permissions for a collection
  And I press the button to create a collection
  Then I should see a failure message for "invalid collection"

Scenario: Updating a collection with invalid permissions
  Given a collection with pid "dri:collperm" created by "user1@user1.com"
  When I go to the "collection" "show" page for "dri:collperm"
  When I follow the link to edit a collection
  And I enter invalid permissions for a collection
  And I press the button to save collection changes
  Then I should see a failure message for "invalid update collection"

Scenario Outline: Adding a Digital Object in a governing/non-governing collection
  Given a Digital Object with pid "<object_pid>" and title "<object_title>"
  And a collection with pid "<collection_pid>"
  When I add the Digital Object "<object_pid>" to the collection "<collection_pid>" as type "<governance_type>"
  Then the collection "<collection_pid>" should contain the Digital Object "<object_pid>" as type "<governance_type>"

  Examples:
    | object_pid | object_title | collection_pid | governance_type |
    | dri:obj1   | Object 1     | dri:coll1      | governing       |
    | dri:obj2   | Object 2     | dri:coll1      | governing       |
    | dri:obj3   | Object 3     | dri:coll2      | non-governing   |
    | dri:obj4   | Object 4     | dri:coll2      | non-governing   |

Scenario Outline: Creating Digital Object in a governing collection using the web forms
  Given a collection with pid "<collection_pid>" created by "user1@user1.com"
  When I create a Digital Object in the collection "<collection_pid>"
  Then the collection "<collection_pid>" should contain the new digital object

  Examples:
    | object_pid | object_title | collection_pid | governance_type |
    | dri:obj1   | Object 1     | dri:coll1      | governing       |

Scenario: Adding a Digital Object to a non-governing collection using the web forms
  Given a Digital Object with pid "dri:obj4" and title "Object 4" created by "user1@user1.com"
  And a collection with pid "dri:coll4" created by "user1@user1.com"
  When I add the Digital Object "dri:obj4" to the non-governing collection "dri:coll4" using the web forms
  And I go to the "collection" "show" page for "dri:coll4"
  Then I should see the Digital Object "dri:obj4" as part of the collection

Scenario: Removing a Digital Object from a non-governing collection using the web forms
  Given a Digital Object with pid "dri:obj5" and title "Object 5" created by "user1@user1.com"
  And a collection with pid "dri:coll5" created by "user1@user1.com"
  When I add the Digital Object "dri:obj5" to the collection "dri:coll5" as type "non-governing"
  Then the collection "dri:coll5" should contain the Digital Object "dri:obj5" as type "non-governing"
  When I go to the "collection" "show" page for "dri:coll5"
  Then I should see the Digital Object "dri:obj5" as part of the collection
  When I press the remove from collection button for Digital Object "dri:obj5"
  Then I should see a success message for removing an object from a collection
  When I go to the "collection" "show" page for "dri:coll5"
  Then I should not see the Digital Object "dri:obj5" as part of the non-governing collection

Scenario: Deleting a collection as an admin
  Given I am not logged in
  Given I am logged in as "admin" in the group "admin"
  Given a collection with pid "dri:coll6" created by "user1@user1.com"
  When I go to the "collection" "show" page for "dri:coll6"
  And I follow the link to edit a collection
  Then I should see a button to delete collection with id dri:coll6
  When I press the button to delete collection with id dri:coll6
  Then I should see a success message for "deleting a collection"

Scenario: Non-admin should not be given option to delete
  Given a collection with pid "dri:coll7" created by "user1@user1.com"
  When I go to the "collection" "show" page for "dri:coll7"
  And I follow the link to edit a collection
  Then I should not see a button to delete collection with id dri:coll7

Scenario: Committing a Digital Object which is a duplicate of an existing Digital Object in the same collection
#  Given a Digital Object with pid "dri:obj6" and title "Object 6"
#  And a collection with pid "dri:coll6"
#  And the collection "dri:coll6" already contains the Digital Object "dri:obj6"
#  When I commit the Digital Object
#  Then I should get a duplicate object warning
#  And I should be given a choice of using the existing object or creating a new one


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
  Then I should see the add you collection details form
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

