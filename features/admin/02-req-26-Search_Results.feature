Feature: Search Results

DELETEME: REQ-26
DELETEME:
DELETEME: The system shall retrieve a list of digital objects based on the search criteria
DELETEME:
DELETEME: 1.1 It shall return digital objects that match the user access rights
DELETEME: 1.2 It shall return metadata that match the user access rights.
DELETEME: 1.3 It shall not return any restricted digital objects or metadata to unauthorized users.

Admin users should see all objects
Collection managers should see all of their collections and objects within their
collections.
Manage and Edit users should see all collections for which they have manage
or edit permission, as well as all objects within those collections.
Manage and Edit users should see all objects for which they have manage or
edit permission.

  Scenario: Admin user can see all objects
    Given I am logged in as "admin" in the group "admin"
    And a collection with pid "dri:coll1" and title "Search Collection 1" created by "user1@user1.com"
    And a Digital Object with pid "dri:obj1", title "Search Object 1" created by "user1@user1.com"
    And the object with pid "dri:obj1" is in the collection with pid "dri:coll1"
    And I am on the home page
    When I press the button to search
    Then I should see a search result "Search Collection 1"
    And I select the "Objects" tab
    Then I should see a search result "Search Object 1"

  Scenario: Collection managers should see all of their collections and objects within their collections
    Given I am logged in as "colmgr" in the group "cm"
    And a collection with pid "dri:coll2" and title "Search Collection 2" created by "colmgr@colmgr.com"
    And a Digital Object with pid "dri:obj2", title "Search Object 2" created by "user1@user1.com"
    And the object with pid "dri:obj2" is in the collection with pid "dri:coll2"
    And I am on the home page
    When I press the button to search
    Then I should see a search result "Search Collection 2"
    And I select the "Objects" tab
    Then I should see a search result "Search Object 2"

  Scenario Outline: Manage/edit users should see all collections for which they have permission
    Given I am logged in as "user2"
    And a collection with pid "dri:coll3" and title "Search Collection 3" created by "user1@user1.com"
    And "user2@user2.com" has been granted "<permission>" permissions on "dri:coll3"
    And I am on the home page
    When I press the button to search
    And I follow the link to collections
    Then I should see a search result "Search Collection 3"

    Examples:
      | permission |
      | edit       |
      | manage     |

  Scenario Outline: Manage/edit users should see all objects in collections for which they have permission
    Given I am logged in as "user3"
    And a collection with pid "dri:coll4" and title "Search Collection 4" created by "user1@user1.com"
    And a Digital Object with pid "dri:obj4", title "Search Object 4" created by "user1@user1.com"
    And the object with pid "dri:obj4" is in the collection with pid "dri:coll4"
    And "user3@user3.com" has been granted "<permission>" permissions on "dri:coll4"
    And I am on the home page
    When I press the button to search
    Then I should see a search result "Search Collection 4"
    And I select the "Objects" tab
    Then I should see a search result "Search Object 4"

    Examples:
      | permission |
      | edit       |
      | manage     |

  Scenario Outline: Manage/edit users should see all objects for which they have permission
    Given I am logged in as "user4"
    And a collection with pid "dri:coll5" and title "Search Collection 5" created by "user1@user1.com"
    And a Digital Object with pid "dri:obj5", title "Search Object 5" created by "user1@user1.com"
    And the object with pid "dri:obj5" is in the collection with pid "dri:coll5"
    And "user4@user4.com" has been granted "<permission>" permissions on "dri:obj5"
    And I am on the home page
    When I press the button to search
    And I select the "Objects" tab
    Then I should see a search result "Search Object 5"

    Examples:
      | permission |
      | edit       |
      | manage     |
