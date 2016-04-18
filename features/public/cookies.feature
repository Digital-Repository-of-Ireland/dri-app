@cookies @javascript @done @req-67
Feature: Cookies alert
  In order to comply with EU e-Privacy Directive
  As an new visitor to the DRI
  I should be informed of the DRI cookie policy
  And I should be able to accept the DRI cookie policy

Background:
  Given I am not logged in

Scenario: Visiting the site for the first time
  Given I am on the home page
  Then I should see a window about cookies
  When I accept cookies terms
  Then I should have a cookie accept_cookies
#  And I should not see a window about cookies

Scenario: Logging in should set accept_cookies
  Given I am on the home page
  Then I should see a window about cookies
  When I am logged in as "user1" and accept cookies
  Then I should not see a window about cookies
