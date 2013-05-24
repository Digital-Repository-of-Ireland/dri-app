@construct @req-17 @done
Feature:
  In order to add a digital object into the repository
  As an authenticated and authorised depositor
  I want to construct a Digital Object

Scenario: Committing a valid Digital Object
  Given a Digital Object
  When I commit the Digital Object
  Then I should be given a PID from the digital repository

Scenario: Committing a Digital Object with incorrectly structured metadata file
  Given a Digital Object
  When I add invalid metadata
  And I commit the Digital Object
  Then I should get an invalid Digital Object
