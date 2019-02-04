@language
Feature: Internationalisation
  In order to provide a bi-lingual repository
  As a user
  I should be able to see the website in English or Irish

  @wip
  Scenario Outline: Not logged in user should see their own language based on their browser
    Given I reset the sessions
    Given I am not logged in and accept cookies
    And my browser language is "<lang>"
    When I go to "the home page"
    Then I should see the language "<lang>"

  Examples:
    | lang |
    | en   |
    | ga   |

  Scenario Outline: Not logged in user changes language using the language selection tab
    Given I reset the sessions
    Given I am not logged in
    And my browser language is "<lang>"
    Then I should see the language "<lang>"
    When I follow the link to change to <lang_new>
    Then I should see the language "<lang_new>"
    And I should have a cookie lang
    And The language cookie content should be <lang_new>

  Examples:
    | lang | lang_new|
    | en   | ga      |
    #| ga   | en      |

  Scenario Outline: A logged in user should see languages that they have set in their profile
    Given I reset the sessions
    Given I am not logged in
    And my browser language is "<lang>"
    When I am logged in as "<lang_user>" with language "<lang_profile_set_to>"
    Then I should see the language "<lang_profile_set_to>"

  Examples:
    | lang | lang_user   | lang_profile_set_to |
    | en   | englishuser | en                  |
    | ga   | englishuser | en                  |
    | ga   | irishuser   | ga                  |
    | en   | irishuser   | ga                  |

  Scenario Outline: Changing Language of a Logged in user with localisation preferences
    Given I reset the sessions
    Given I am not logged in
    And my browser language is "<lang>"
    Given I am logged in as "<lang_user>" with language "<lang_profile_set_to>"
    Then I should see the language "<lang_profile_set_to>"
    When I follow the link to change to <lang_new>
    Then I should see the language "<lang_new>"
    And I should have a cookie lang
    And The language cookie content should be <lang_new>

  Examples:
    | lang | lang_user   | lang_profile_set_to | lang_new |
    | en   | englishuser | en                  | ga       |
    | en   | englishuser | ga                  | en       |
    | ga   | englishuser | ga                  | en       |
    | ga   | englishuser | en                  | ga       |
    | ga   | irishuser   | ga                  | en       |
    | ga   | irishuser   | en                  | ga       |
    | en   | irishuser   | ga                  | en       |
    | en   | irishuser   | en                  | ga       |

# This test fails at "And The language cookie content should be ga" it seems due to capybara caching the cookies because having checked the values in the wokflow logic seems working properly
  @wip
  Scenario: Changing Language of a Logged in user with localisation preferences with a cookie already set
    Given I am not logged in
    And I reset the sessions
    And I should not have a cookie lang
    And I have a "lang" cookie set to "en"
    And I should have a cookie lang
    And The language cookie content should be en
    And my browser language is "en"
    Given I am logged in as "englishuser" with language "en"
    Then I should see the language "en"
    When I follow the link to change to ga
    Then I should see the language "ga"
    And I should have a cookie lang
    And The language cookie content should be ga
    When I follow the link to my workspace
    And I follow the link to view my account
    Then My language preferences should be "Rogha Teangan: Gaeilge"

  Scenario Outline: Changing Language of a Logged in user without localisation preferences
    Given I reset the sessions
    Given I am not logged in
    And my browser language is "<lang>"
    And I am logged in as "<lang_user>" with no language
    Then I should see the language "<lang>"
    Then I should see a link to change to <lang_new>
    When I follow the link to change to <lang_new>
    Then I should see the language "<lang_new>"
    And I should have a cookie lang
    And The language cookie content should be <lang_new>

  Examples:
  | lang | lang_user  | lang_new |
  | en   | nolanguser | ga       |
#  | ga   | nolanguser | en       |
