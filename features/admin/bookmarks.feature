@javascript
Feature: Bookmarks Feature
  I should be able to add, remove and show bookmarks

  Background:
    Given I am logged in as "admin" in the group "admin" and accept cookies
    And a collection with pid "bookcoll" and title "Bookmark Test Collection"
    And a Digital Object with pid "bookobj" and title "Bookmark Test Object" in collection "bookcoll"
    And the collection is published

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
    Given I check "toggle_bookmark_bookcoll"
    And I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"

  Scenario: Remove bookmark
    Given I am on the home page
    When I perform a search
    And I follow the link to browse
    And I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle_bookmark_bookcoll"
    And I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"
    Given I click the link to remove bookmark
    #And I wait for the ajax request to finish
    Then I should see "no bookmark"

  Scenario: Clear all bookmarks
    Given I am on the home page
    When I perform a search
    And I follow the link to browse
    And I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle_bookmark_bookcoll"
    And I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"
    Given I follow the link to clear bookmarks
    #And I wait for the ajax request to finish
    Then I should see "no bookmark"
