Feature: Ingestion

DELETEME: REQ-17
DELETEME: 
DELETEME: The system shall enable the user to ingest digital objects into a
DELETEME: collection in accordance with their access rights.
DELETEME: 
DELETEME: 1. It shall check for duplicate digital objects on a collection basis. (e.g. check metadata).
DELETEME: 2. It shall warn users of any duplications.
DELETEME: 3. It shall check, validate and verify the digital object (check integrity)
DELETEME: 4. It may provide a replace operator to replace a digital object.
DELETEME: 
DELETEME: ---
DELETEME: 
DELETEME: In order to <meet goal>
DELETEME: As a <stakeholder>
DELETEME: I want <a feature>
DELETEME: 
DELETEME: ----

In order to add a digital object into the repository
As an authenticated and authorised depositor
I want to ingest an asset with metadata

Scenario: Ingesting a Digital Object
  Given the asset SAMPLEA
  And a metadata file SAMPLEA.xml
  When I ingest the files SAMPLEA and SAMPLEA.xml
  Then I check my digital repository for duplicates
  Then I check my collections for duplicates
  But there must be no duplicates
  Then I inspect the asset for the file metadata and record this information
  Then I validate the metadata file
  Then I ingest the assest with the metadata
  Then I should be given a DOI from the digital repository

Scenario: Ingesting a Digital Object with an invalid asset
  Given the asset SAMPLEA
  And a metadata file SAMPLEA.xml
  When I ingest the files SAMPLEA and SAMPLEA.xml
  Then I check my digital repository for duplicates
  Then I check my collections for duplicates
  But there must be no duplicates
  Then I inspect the asset for the file metadata and record this information
  But the asset is invalid
  Then I should raise an exception

Scenario: Ingesting a Digital Object with invalid metadata
  Given the asset SAMPLEA
  And a metadata file SAMPLEA.xml
  When I ingest the files SAMPLEA and SAMPLEA.xml
  Then I check my digital repository for duplicates
  Then I check my collections for duplicates
  But there must be no duplicates
  Then I inspect the asset for the file metadata and record this information
  Then I validate the metadata file
  But the metadata is invalid
  Then I should raise an exception
