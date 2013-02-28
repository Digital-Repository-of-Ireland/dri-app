@cookies @javascript
Feature:
  In order to comply with EU e-Privacy Directive
  As an new visitor to the DRI
  I should be informed of the DRI cookie policy
  And I should be able to accept the DRI cookie policy

Background:
  Given I am not logged in

Scenario: Visiting the site for the first time
  Given I am on the home page
  Then I should see a message for cookie notification
  When I press the button to accept cookie policy
  Then I should have a cookie accept_cookies
  And I should not see a message for cookie notification

Scenario: Logging in should set accept_cookies
  Given I am on the home page
  Then I should see a message for cookie notification
  When I am logged in as "user1"
  Then I should not see a message for cookie notification
