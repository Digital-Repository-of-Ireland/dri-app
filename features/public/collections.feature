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

