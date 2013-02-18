@collections @req-17
Feature:
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to add my Digital Objects to a collection
  And to retrieve my Digital Objects by collection

  What comes first?
    - collections or objects?
	  - collections first? - DG
    - from user perspective - users will want to view collections (which is curated)
	- need to know the type of user, researchers are different from general public
	  - focus on depositor for req-17
	- hydra frame work supports collections but objects can't be in two collections due to access policies

  Implementation plan/goal
	- One level of depth in repository for collections
	  - new data model (collections model???) (DG)
	    - need two rights metadata - one for "itself" and one for "managed objects"
		- need for cucumber scenario
	    - Objects are only in one collection
		- Need for organisation/institution name/code

  Note: ingest will need to know about collections when committing objects

Background:
  Given I am logged in as "user1"

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

Scenario: Adding a Digital Object in a governing collection
  Given a Digital Object with pid "dri:obj1" and title "Object 1"
  And a collection with pid "dri:coll1"
  When I add the Digital Object "dri:obj1" to the collection "dri:coll1" as type governing
  Then the collection "dri:coll1" should contain the Digital Object "dri:obj1" as type governing

Scenario: Adding a Digital Object to a non-governing collection
  Given a Digital Object with pid "dri:obj1" and title "Object 1"
  And a collection with pid "dri:coll1"
  When I add the Digital Object "dri:obj1" to the collection "dri:coll1" as type non-governing
  Then the collection "dri:coll1" should contain the Digital Object "dri:obj1" as type non-governing

Scenario: Creating Digital Object in a governing collection using the web forms
  Given a collection with pid "dri:coll1"
  When I create a Digital Object in the collection "dri:coll1"
  And I go to the show page for the collection "dri:coll1"
  Then I should see the Digital Object "dri:obj1" as part of the collection

@javascript
Scenario: Adding a Digital Object to a non-governing collection using the web forms
  Given a Digital Object with pid "dri:obj1" and title "Object 1"
  And a collection with pid "dri:coll1"
  When I add the Digital Object "dri:obj1" to the non-governing collection "dri:coll1" using the web forms
  And I go to the show page for the collection "dri:coll1"
  Then I should see the Digital Object "dri:obj1" as part of the collection

Scenario: Removing a Digital Object from a non-governing collection using the web forms
  Given a Digital Object with pid "dri:obj1" and title "Object 1"
  And a collection with pid "dri:coll1"
  When I add the Digital Object "dri:obj1" to the collection "dri:coll1" as type non-governing
  Then the collection "dri:coll1" should contain the Digital Object "dri:obj1" as type non-governing
  When I go to the show page for the collection "dri:coll1"
  Then I should see the Digital Object "dri:obj1" as part of the collection
  When I press the remove from collection button for Digital Object "dri:obj1"
  And I go to the show page for the collection "dri:coll1"
  Then I should not see the Digital Object as part of the non-governing collection

Scenario: Committing a Digital Object which is a duplicate of an existing Digital Object in the same collection
#  Given a Digital Object with pid "dri:obj1" and title "Object 1"
#  And a collection with pid "dri:coll1"
#  And the collection "dri:coll1" already contains the Digital Object "dri:obj1"
#  When I commit the Digital Object
#  Then I should get a duplicate object warning
#  And I should be given a choice of using the existing object or creating a new one

