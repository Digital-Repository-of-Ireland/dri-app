@req-20
Feature: Saved Search criteria


  Scenario: Check no saved searches
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
    And I go to "my saved search page"
    Then I should see a "no saved search"

  Scenario: Save collection search
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "collections" tab
    Then I should see a search result "Sample Collection"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Collections (sample)"

  Scenario: Delete collection saved search
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
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
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "collections" tab
    Then I should see a search result "Sample Collection"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Collections (sample)"
    When I press the button to clear saved search
    Then I should see a "Successfully removed that saved search"
    And I should see a "no saved search"

  Scenario: Save object search
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "objects" tab
    Then I should see a search result "SAMPLE AUDIO TITLE"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Objects (sample)"

  Scenario: Delete object saved search
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
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
    Given I am logged in as "user1"
    Given a collection with pid "dri:coll55" and title "Sample Collection" created by "user1"
    And I have created a "Sound" object with metadata "SAMPLEA.xml" in the collection "Sample Collection"
    When I fill in "q" with "sample"
    And I press the button to search
    And I select the "objects" tab
    Then I should see a search result "SAMPLE AUDIO TITLE"
    When I press the button to save search
    And I go to "my saved search page"
    Then I should see a search result "Objects (sample)"
    When I press the button to clear saved search
    Then I should see a "Successfully removed that saved search"
    And I should see a "no saved search"
