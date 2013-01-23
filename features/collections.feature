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

Scenario: Commiting Digital Object to a collection that does not yet exist
  Given a Digital Object
  And a collection that does not exist
  When I add the Digital Object to a collection
  Then the collection should exist
  And the collection should contain the Digital Object

Scenario: Committing a Digital Object which is a duplicate of an existing Digital Object in the same collection
  Given a Digital Object
  And an existing collection
  And the collection already contains the Digital Object
  When I commit the Digital Object
  Then I should get a duplicate object warning
  And I should be given a choice of using the existing object or creating a new one

Scenario: Retrieving Digital Objects by collection
  Given an existing collection
  When I retrieve the collection
  Then I should see my Digital Objects
