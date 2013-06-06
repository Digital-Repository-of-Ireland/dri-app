@req-17.7 @done
Feature: Bulk Ingest

In order to add a number of digital objects into the repository
As an authenticated and authorised depositor
I want to ingest a number of objects with an asset with metadata

This is currently implemented in the commandline app

# this is a repeat of the current collections and construct digital objects
# feature files, this bulk ingest feature may not needed if there isn't going
# to be a web front end will need a fixture for existing collection and a few
# objects

#
# One metadata.xml file and one asset
# metadata is qualified dublin core
# Bulk ingest a set of objects into one collection
#
# one directory of files containing metadata and assets
#
# would be nice to have a config file in directory for bulk ingest
#   ingest.conf
#
# create collection
# grant user depositor permission
#
# need to specify scenario for user who has no permissions to select a
# collection for ingest
#
# need to do checksumming of data on ingest

@noexec
Scenario: Bulk Ingest of a directory 10 of assets and metadata.xml files
  Given I am logged in as "user1"
  And there is an existing collection
  And I have depositor permissions for the collection
  And there is a valid "bulk ingest" location
  And the "Digital Assets" are valid
  And the metadata are valid
  When I select the collection
  And I specify the "bulk ingest" location
  And I run the "bulk ingest" command-line tool
  Then the digital objects should be created in the collection
  And I should get a "report"
  And it should have a list of "PIDs"
  And it should have a list of "URLs"
  And it should have a list of "checksums"

@noexec @wip
Scenario: Bulk ingest via a GUI using prepared metadata and assets
  Given I am logged in as "user1"
  And I am on the page for "Bulk Ingest via upload"
  And there is an existing collection
  And I have depositor permissions for the collection
  And there is a valid "bulk ingest" location
  And the "Digital Assets" are valid
  And the metadata are valid
  When I select the collection
  And I specify the "bulk ingest" location
  And I click the button for "Ingest"
  Then the digital objects should be created in the collection
  And I should get a "report"
  And it should have a list of "PIDs"
  And it should have a list of "URLs"
  And it should have a list of "checksums"

# Assumption:
#   A depositor may have a set of assets and want to create
#   metadata via a web form
#   This is just an idea for an alternative way to implement
#   bulk ingest. We may not implement it.
@noexec @experimental @wip
Scenario: Bulk ingest via a GUI using form entry for metadata
  Given I am logged in as "user1"
  And I am on the page for "Bulk Ingest via form entry"
  And there is an existing collection
  And I have depositor permissions for the collection
  And a set of asset files exist
  And the "Digital Assets" are valid
  And the metadata does not exist
  When I select the collection
  And I specify location of the asset files
  And I fill in valid shared metadata in the web form for the assets
  And I click the button for "Ingest"
  Then the digital objects should be created in the collection
  And I should get a "report"
  And it should have a list of "PIDs"
  And it should have a list of "URLs"
  And it should have a list of "checksums"
  And all of the shared metadata fields will be set for each of the digital objects
  And the digital objects will be set as requiring review

