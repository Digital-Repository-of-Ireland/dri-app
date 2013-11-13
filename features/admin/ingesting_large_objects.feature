@noexec

Feature: Ingesting Large Objects

Assumptions:
  * Users will be using a desktop/laptop computer with a reasonably-sized screen
    * Users will not be ingesting from hand-held/mobile devices
  * Users will be on a fast, reliable and secure network (typically HEANet)
  * Ingestion of very large objects may be done at partner sites
    * e.g. users may bring files to partner site on hard drive

Scenario Outline: In order to ingest large assets (e.g. 1+ GB image file)
  Given I have a large asset file
  And there is an existing collection
  And I have depositor permissions for the collection
  And the large asset file exists at <location>
  And I am using <protocol>
  And I have access to the file at <location> via <protocol>
  And the large asset file is valid
  And the metadata are valid
  When I ingest the large asset file
  And I read from <location> via <protocol>
  Then I should be able to ingest without failures

  Examples:
    | protocol | location         |
    | posix    | /file            |
    | HTTP GET | http://location/ |

