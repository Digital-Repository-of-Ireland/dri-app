@collections @req-17
Feature:
  In order to manage my Digital Objects
  As an authorized user
  I want to be able to add my Digital Objects to a collection
  And to retrieve my Digital Objects by collection

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
  Given a Digital Object with pid "dri:obj2" and title "Object 2"
  And a collection with pid "dri:coll2"
  When I add the Digital Object "dri:obj2" to the collection "dri:coll2" as type non-governing
  Then the collection "dri:coll2" should contain the Digital Object "dri:obj2" as type non-governing

Scenario: Creating Digital Object in a governing collection using the web forms
  Given a collection with pid "dri:coll3"
  When I create a Digital Object in the collection "dri:coll3"
  Then the collection "dri:coll3" should contain the new digital object

Scenario: Adding a Digital Object to a non-governing collection using the web forms
  Given a Digital Object with pid "dri:obj4" and title "Object 4"
  And a collection with pid "dri:coll4"
  When I add the Digital Object "dri:obj4" to the non-governing collection "dri:coll4" using the web forms
  And I go to the show page for the collection "dri:coll4"
  Then I should see the Digital Object "dri:obj4" as part of the collection

Scenario: Removing a Digital Object from a non-governing collection using the web forms
  Given a Digital Object with pid "dri:obj5" and title "Object 5"
  And a collection with pid "dri:coll5"
  When I add the Digital Object "dri:obj5" to the collection "dri:coll5" as type non-governing
  Then the collection "dri:coll5" should contain the Digital Object "dri:obj5" as type non-governing
  When I go to the show page for the collection "dri:coll5"
  Then I should see the Digital Object "dri:obj5" as part of the collection
  When I press the remove from collection button for Digital Object "dri:obj5"
  Then I should see a success message for removing an object from a collection
  When I go to the show page for the collection "dri:coll5"
  Then I should not see the Digital Object "dri:obj5" as part of the non-governing collection

Scenario: Committing a Digital Object which is a duplicate of an existing Digital Object in the same collection
#  Given a Digital Object with pid "dri:obj6" and title "Object 6"
#  And a collection with pid "dri:coll6"
#  And the collection "dri:coll6" already contains the Digital Object "dri:obj6"
#  When I commit the Digital Object
#  Then I should get a duplicate object warning
#  And I should be given a choice of using the existing object or creating a new one

