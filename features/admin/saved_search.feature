@req-20
Feature: Saved Search criteria

  Background:
    Given I am logged in as "user1"
    Given a collection with pid "coll55" and title "Sample Collection" created by "user1"
    And I have created an object with metadata "SAMPLEA.xml" in the collection with pid "coll55"

  Scenario: Check no saved searches
    And I go to "my saved search page"
    Then I should see a "no saved search"

  Scenario: Save collection search
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "collections" tab
    Then I should see a search result "Sample Collection"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Collections (sample)"

  Scenario: Delete collection saved search
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "collections" tab
    Then I should see a search result "Sample Collection"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Collections (sample)"
    When I press the button to delete saved search
    Then I should see a "Successfully removed that saved search"
    And I should see a "no saved search"

  Scenario: Clear saved collection search
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "collections" tab
    Then I should see a search result "Sample Collection"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Collections (sample)"
    When I follow the link to clear saved search
    Then I should see a "Successfully removed that saved search"
    And I should see a "no saved search"

  Scenario: Save object search
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "objects" tab
    Then I should see a search result "SAMPLE AUDIO TITLE"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Objects (sample)"

  Scenario: Delete object saved search
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "objects" tab
    Then I should see a search result "SAMPLE AUDIO TITLE"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Objects (sample)"
    When I press the button to delete saved search
    Then I should see a "Successfully removed that saved search"
    And I should see a "no saved search"

  Scenario: Clear saved object search
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "objects" tab
    Then I should see a search result "SAMPLE AUDIO TITLE"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Objects (sample)"
    When I follow the link to clear saved search
    Then I should see a "Successfully removed that saved search"
    And I should see a "no saved search"
