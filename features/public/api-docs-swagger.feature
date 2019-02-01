@javascript

Feature: API Docs
  As a public User
  I want to see documentation for the API

Background:
  Given I am on the api docs page

Scenario: Visiting the api docs page
  Then I should see 1 visible element "#login"
  And I click the "login" button
  Then I should be on the User Signin page
