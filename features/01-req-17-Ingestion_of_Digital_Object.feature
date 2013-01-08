@req-17 @ingest
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

Background:
  Given that I am logged in
  And that I have an existing collection

@wip
Scenario: Ingesting a Digital Object of 1 file
  Given the asset SAMPLEA
  Given that the asset is only 1 file
  Given a known collection
  And a metadata file SAMPLEA.xml
  When I ingest the files SAMPLEA and SAMPLEA.xml
  Then I validate the metadata file
  Then I attempt to validate the data file against a mime type database
  Then I perform an Anti Viral check on the data file
  Then I check my collections for duplicates
  But if there are duplicates warn the user and give the user a choice of using the existing object or create a new one
  Then I inspect the asset for the file metadata and record this information
  Then I ingest the assest with the metadata
  Then I should be given a PID from the digital repository

Scenario: Constructing a valid Digital Object
  Given a metadata file "valid_metadata.xml"
  When I visit the new Digital Object page
  And I upload the metadata file "valid_metadata.xml"
  Then I should see "Audio object has been successfully ingested"
  And the collection should contain the Digital Object
  And the Digital Object metadata should match "valid_metadata.xml" 
  
Scenario: Constructing an invalid Digital Object
  Given a metadata file "invalid_metadata.xml"
  When I visit the new Digital Object page
  And I upload the metadata file "invalid_metadata.xml"
  Then I should see "Audio object has invalid metadata"
  And the collection should not contain the Digital Object

Scenario: Committing a valid Digital Object
  Given a valid Digital Object
  When I commit the Digital Object to the collection
  Then I should be given a PID from the digital repository
  And the collection should contain the Digital Object

Scenario: Committing an invalid Digital Object with incorrectly structured metadata file
  Given a Digital Object with invalid metadata
  When I commit the Digital Object to the collection
  Then I should get an error
  And the collection should not contain the Digital Object

Scenario: Committing an invalid Digital Object with an invalid asset
  Given a Digital Object with invalid asset "SAMPLEA"
  When I commit the Digital Object to the collection
  Then I should get an error
  And the collection should not contain the Digital Object

Scenario: Ingesting a Digital Object which is a duplicate of an existing Digital Object in the same collection
  Given a valid Digital Object
  And that the collection already contains the Digital Object
  When I commit the Digital Object
  Then I should get a warning
  And I should be given a choice of using the existing object or creating a new one

#Scenario: Ingesting a Digital Object with an invalid asset
#  Given the asset SAMPLEA
#  Given a known collection
#  And a metadata file SAMPLEA.xml
#  When I ingest the files SAMPLEA and SAMPLEA.xml
#  Then I check my digital repository for duplicates
#  Then I check my collections for duplicates
#  But there must be no duplicates
#  Then I inspect the asset for the file metadata and record this information
#  But the asset is invalid
#  Then I should raise an exception
#
#Scenario: Ingesting a Digital Object with invalid metadata
#  Given the asset SAMPLEA
#  Given a known collection
#  And a metadata file SAMPLEA.xml
#  When I ingest the files SAMPLEA and SAMPLEA.xml
#  Then I check my digital repository for duplicates
#  Then I check my collections for duplicates
#  But there must be no duplicates
#  Then I inspect the asset for the file metadata and record this information
#  Then I validate the metadata file
#  But the metadata is invalid
#  Then I should raise an exception
