@noexec @wip
Feature: Workflows for a user administrator


  Scenario: ban a user

  Scenario: unban a user

  Scenario: delete a user
    Given I am logged in as the user administrator user
    And I want to delete a user account
    When I hover over 'Users & Groups'
    Then the user_groups submenu should appear
    When I click on the link for Users
    Then I should see a list of users
    When I click on the link to delete a user
    Then I should see a confirmation dialog
    When I click OK on the confirmation dialog
    Then the user should be deleted



  Scenario: add a user (same as registering)


  Scenario: Reset a user's password
    Given I am logged in as the user administrator user
    And I want to reset the password for a user
    When I hover over 'Users & Groups'
    Then the user_groups submenu should appear
    When I click on the link for Users
    Then I should see a list of users
    When I click on the link to view a user's profile
    Then I should see the user's profile
    When I click on the link to edit profile
    Then I should see the edit profile form
    When I fill in a password
    And I fill in a password confirmation
    And I press the button to Update
    Then the user's password should be updated



  Scenario: Reporting

  Scenario: CRUD User Agreements

  Scenario: Block objects

  Scenario: Remove permissions


  Scenario: Make a user a CM
    Given I am logged in as the user administrator user
    And I want to create a new CM user
    And the user exists
    When I hover over 'Users & Groups'
    Then the user_groups submenu should appear
    When I click on the link for Groups
    Then I should see a list of groups
    When I click on the link for the CM group
    Then I should see the CM group page
    When I click on the link to edit group
    Then I should see the edit group form
    When I enter a valid email address of a user
    And I press the button to Join Group
    Then The user should be added to the group


  Scenario: Remove user from CM
    Given I am logged in as the user administrator user
    And I want to remove a CM user
    And the user exists
    And the user is a CM
    When I hover over 'Users & Groups'
    Then the user_groups submenu should appear
    When I click on the link for Groups
    Then I should see a list of groups
    When I click on the link for the CM group
    Then I should see the CM group page
    When I click on the link to edit group
    Then I should see the edit group form
    And I should see a list of users in the CM group
    When I click on 'Remove' beside the user
    Then the user should be removed from the CM group
    And the user should no longer be able to create collections



