@javascript
Feature: Bookmarks Feature
  I should be able to add, remove and show bookmarks

  Background:
    Given I am logged in as "admin" in the group "admin"
    And a collection with pid "bookcoll" and title "Bookmark Test Collection"
    And a Digital Object with pid "bookobj" and title "Bookmark Test Object" in collection "bookcoll"
    And the collection is published
    When I am on the home page
    And I perform a search

  Scenario: Check no bookmarks
    When I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I follow the link to manage bookmark
    Then I should see "no bookmark"

  Scenario: Add new bookmark
    When I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle-bookmark_bookcoll"
    And I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"

  Scenario: Remove bookmark
    When I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle-bookmark_bookcoll"
    And I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"
    Given I click the link to remove bookmark for id bookcoll
    Then I should see "no bookmark"

  Scenario: Clear all bookmarks
    When I follow "Bookmark Test Collection" within "div.dri_result_container"
    Then I should see "Manage Your Bookmarks"
    Given I check "toggle-bookmark_bookcoll"
    And I follow the link to manage bookmark
    Then I should see "Bookmark Test Collection"
    Given I choose to clear all bookmarks
    Then I should see "no bookmark"
