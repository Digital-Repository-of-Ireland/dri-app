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

Scenario: Bulk Ingest of a directory 10 of assets and metadata.xml files
  Given I am logged in as "user1"
  And there is an existing collection
  And I have depositor permissions for the collection
  And there is a valid "bulk ingest" location
  And the "Digital Assets" are valid
  And the metadata are valid
  When I select the collection
  And I specify the "bulk ingest" location
  And I run the "bulk ingest" tool
  Then the digital objects should be created in the collection
  And I should get a "report"
  And it should have a list of "PIDs"
  And it should have a list of "URLs"
  And it should have a list of "checksums"
