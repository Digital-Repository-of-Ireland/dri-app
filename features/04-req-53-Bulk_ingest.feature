Feature: Bulk Ingest

DELETEME: REQ-53
DELETEME: 
DELETEME: The system may allow bulk ingestion.

In order to add a number of digital objects into the repository
As an authenticated and authorised depositor
I want to ingest a number of objects with an asset with metadata

# this is a repeat of the current collections and construct digital objects
# feature files, this bulk ingest feature may not needed if there isn't going
# to be a web front end will need a fixture for existing collection and a few
# objects
Scenario: Bulk Ingest of a set of objects
  Given an existing collection
  Given a Digital Object "A"
  Given a Digital Object "B"
  Given a Digital Object "C"
  When I commit the Digital Object "A"
  And I commit the Digital Object "B"
  And I commit the Digital Object "C"
