@javascript
Feature:
  I should be able to add, remove and show bookmarks

  Background:
    Given I am logged in as "admin" in the group "admin" and accept cookies
    And a collection with pid "dri:bookcoll" and title "Bookmark Test Collection"
    And a Digital Object with pid "dri:bookobj" and title "Bookmark Test Object"
    And the object with pid "dri:bookobj" is in the collection with pid "dri:bookcoll"

  Scenario: Check no bookmarks
    Given I am on the home page
    When I perform a search
    And I follow the link to browse
    And I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I follow the link to manage bookmark
    Then I should see "no bookmark"

  Scenario: Add new bookmark
    Given I am on the home page
    When I perform a search
    And I follow the link to browse
    And I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle_bookmark_dri:bookcoll"
    And I wait for the ajax request to finish
    Given I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"

  Scenario: Remove bookmark
    Given I am on the home page
    When I perform a search
    And I follow the link to browse
    And I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle_bookmark_dri:bookcoll"
    And I wait for the ajax request to finish
    Given I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"
    Given I follow the link to remove bookmark
    Then I should see "no bookmark"

  Scenario: Clear all bookmarks
    Given I am on the home page
    When I perform a search
    And I follow the link to browse
    And I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle_bookmark_dri:bookcoll"
    And I wait for the ajax request to finish
    Given I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"
    Given I follow the link to clear bookmarks
    Then I should see "no bookmark"
