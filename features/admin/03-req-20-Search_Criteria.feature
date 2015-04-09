# search by various dates, by format, location, subject and free text supported.
# Search by digital object owner is not supported on the public head, but you
# can search by collection instead.
# Facet searching and boolean logic search supported
# fuzzy string needs further definition

@req-20
Feature: Search criteria

DELETEME: REQ-20
DELETEME:
DELETEME: The system shall allow users to refine search criteria through facet search
DELETEME:
DELETEME: 1.1 It shall allow users to refine search criteria by date
DELETEME: 1.2 It shall allow users to refine search criteria by data type (e.g. images, audio)
DELETEME: 1.3 It shall allow users to refine search criteria by subject
DELETEME: 1.4 It shall allow users to refine search criteria by location
DELETEME: 1.5 It shall allow users to refine search criteria by free text keyword
DELETEME: 1.6 It shall allow users to refine search criteria by digital object owner
DELETEME: 1.7 It shall allow users to carry out basic and advanced facet searching including Boolean logic.
DELETEME: 1.8 It shall support fuzzy string matching.

In order to search for objects in the repository
As an authenticated and authorised
I want to be able to use the faceted search interface

# sorting of results => see req-26
# Need to ask sharon
# Does not specify if the date is creation, published, upload or broadcast
# Based on current facets, need confirmation that these are correct
# Note that facets do not appear on the main page
# Thus we need to perform an empty search first
# This is probably a bug, need confirmation of what should appear on main page
  Scenario Outline: Faceted Search for a normal end-user (anonymous or registered)
  Given a collection with pid "dri:collection" and title "Test collection" created by "admin"
  And an object in collection "dri:collection" with metadata from file "SAMPLEA.xml"
  And I am not logged in
  When I go to "the home page"
  And I press the button to search
  And I select the "objects" tab
  And I search for "<search>" in facet "<facetname>" with id "<facetid>"
  Then I should see a search result "<result>"

  Examples:
    | facetname  | facetid                              | search          | result             |
    | Subjects   | blacklight-subject_sim               | subject1        | SAMPLE AUDIO TITLE |
    | Places     | blacklight-geographical_coverage_sim | SAMPLE COUNTRY  | SAMPLE AUDIO TITLE |
    | Names      | blacklight-person_sim                | Collins         | SAMPLE AUDIO TITLE |
    | Language   | blacklight-language_sim              | English         | SAMPLE AUDIO TITLE |
    | Mediatype  | blacklight-file_type_display_sim     | Audio           | SAMPLE AUDIO TITLE |
    | Collection | blacklight-root_collection_id_sim    | Test collection | SAMPLE AUDIO TITLE |
    #| Institute  | blacklight-institute_sim             | Test Institute  | SAMPLE AUDIO TITLE |

@wip
Scenario Outline: Faceted Search for admin user
  Given I am logged in as "admin" in the group "admin"
  Given a collection with pid "dri:collection" and title "Test collection" created by "user1"
  And an object in collection "dri:collection" with metadata from file "SAMPLEA.xml"
  When I go to "the home page"
  And I press the button to search
  And I search for "<search>" in facet "<facetname>" with id "<facetid>"
  Then I should see a search result "<result>"

  Examples:
    | facetname                    | facetid                                  | search          | result             |
    | Record Status                | blacklight-status_sim                    | published       | SAMPLE AUDIO TITLE |
    | Metadata Search Access       | blacklight-private_metadata_isi          | Public          | SAMPLE AUDIO TITLE |
    | Master File Access           | blacklight-master_file_isi               | Private         | SAMPLE AUDIO TITLE |
    | Subjects (in English)        | blacklight-subject_eng_sim               | subject1        | SAMPLE AUDIO TITLE |
    | Subject (Place) (in English) | blacklight-geographical_coverage_eng_sim | SAMPLE COUNTRY  | SAMPLE AUDIO TITLE |
    | Subject (Era) (in English)   | blacklight-temporal_coverage_eng_sim     | SAMPLE ERA      | SAMPLE AUDIO TITLE |
    | Depositor                    | blacklight-depositor_sim                 | user1@user1.com | SAMPLE AUDIO TITLE |

# The following two features could be tested via the all fields / search box
#
# Boolean Logic seeems to be "and" right now in gui, the search box may allow for more/less
# need to be broken up into two scenarios
# Scenario: Search using basic and advanced facet searching including Boolean logic
Scenario: Successful search using AND boolean search string
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "sample AND audio"
  And I press the button to search
  And I select the "objects" tab
  Then I should see a search result "SAMPLE AUDIO TITLE"
  When I fill in "q" with "sample + audio"
  And I press the button to search
  Then I should see a search result "SAMPLE AUDIO TITLE"

Scenario: Unsuccessful search using AND boolean search string
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "invalidstring AND audio"
  And I press the button to search
  And I select the "objects" tab
  Then I should not see a search result "Sample Object"

Scenario: Successful search using OR boolean search string
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "sample OR audio"
  And I press the button to search
  And I select the "objects" tab
  Then I should see a search result "SAMPLE AUDIO TITLE"
  When I fill in "q" with "invalidstring OR audio"
  And I press the button to search
  Then I should see a search result "SAMPLE AUDIO TITLE"

Scenario: Unsuccessful search using OR boolean search string
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "invalidstring1 OR invalidstring2"
  And I press the button to search
  And I select the "objects" tab
  Then I should not see a search result "Sample Object"

Scenario: Successful search using NOT boolean search string
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "NOT invalidstring"
  And I press the button to search
  And I select the "objects" tab
  Then I should see a search result "SAMPLE AUDIO TITLE"

Scenario: Unsuccessful search using NOT boolean search string
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "NOT sample"
  And I press the button to search
  And I select the "objects" tab
  Then I should not see a search result "Sample Object"

Scenario: Successful search using "+"
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "+sample"
  And I press the button to search
  And I select the "objects" tab
  Then I should see a search result "SAMPLE AUDIO TITLE"

Scenario: Unsuccessful search using "+"
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "+invalidstring"
  And I press the button to search
  And I select the "objects" tab
  Then I should not see a search result "Sample Object"

Scenario: Successful search using "-"
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "-invalidstring"
  And I press the button to search
  And I select the "objects" tab
  Then I should see a search result "SAMPLE AUDIO TITLE"

Scenario: Unsuccessful search using "-"
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "-sample"
  And I press the button to search
  And I select the "objects" tab
  Then I should not see a search result "Sample Object"

Scenario: Wildcard search
  Given I am logged in as "user1"
  Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "dri:coll55"
  When I fill in "q" with "*"
  And I press the button to search
  And I select the "objects" tab
  Then I should see a search result "SAMPLE AUDIO TITLE"

# This is a configuration option in SOLR? May impact Irish searches
# fuzziness isn't well defined in this case
# where and does it need to be in irish
Scenario: Search shall support fuzzy string matching
