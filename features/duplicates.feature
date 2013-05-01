@req-17 @duplicates
Feature: Duplicates

Store md5 of metadata datastream in Properties, search for match after object creation, warn if found?

DELETEME: REQ-17
DELETEME:
DELETEME: The system shall enable the user to ingest digital objects into a
DELETEME: collection in accordance with their access rights.
DELETEME:
DELETEME: 1. It shall check for duplicate digital objects on a collection basis. (e.g. check metadata).
DELETEME: 2. It shall warn users of any duplications.
DELETEME:
DELETEME: ---
DELETEME:
DELETEME: In order to <meet goal>
DELETEME: As a <stakeholder>
DELETEME: I want <a feature>
DELETEME:
DELETEME: ----

When I ingest a digital object into a collection in the repository
As an authenticated and authorised depositor
I want to be warned of any possible duplicate objects already contained in the collection

Background:
  Given I am logged in as "user1"
  Given a Digital Object with pid "dri:obj1" and title "A Test Object"
  And a collection with pid "dri:col1"
  When I add the Digital Object "dri:obj1" to the collection "dri:col1" as type "governing"
  Then the collection "dri:col1" should contain the Digital Object "dri:obj1" as type "governing"

@wip
Scenario: Ingesting a duplicate Digital Object
  Given a Digital Object with pid "dri:obj2" that is a duplicate of "dri:obj1"
  When I add the Digital Object "dri:obj2" to the collection "dri:col1" as type "governing"
  Then I should see a duplicate object warning containing pid "dri:obj1"
  And the collection "dri:col1" should contain the Digital Object "dri:obj2" as type "governing"
