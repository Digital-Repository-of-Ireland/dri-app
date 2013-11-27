@language
Feature:

  In order to provide a bi-lingual repository
  As a user
  I should be able to see the website in English or Irish

Scenario Outline: Not logged in user should see their own language based on their browser
  Given my browser language is "<lang>"
  And I am not logged in
  Then I should see the language "<lang>"

  Examples:
    | lang |
    | en   |
    | ga   |


Scenario Outline: A logged in user should see languages that they have set in their profile
  Given my browser language is "<lang>"
  When I am logged in as "<lang_user>" with language "<lang_profile_set_to>"
  Then I should see the language "<lang_profile_set_to>"

  Examples:
    | lang | lang_user   | lang_profile_set_to |
    | en   | englishuser | en                  |
    | ga   | englishuser | en                  |
    | ga   | irishuser   | ga                  |
    | en   | irishuser   | ga                  |


Scenario Outline: Changing from Language set in the profile to a different Language
  Given my browser language is "<lang>"
  Given I am logged in as "<lang_user>" with language "<lang_profile_set_to>"
  Then I should see the language "<lang_profile_set_to>"
  When I follow the link to view my account
  And I follow the link to edit my account
  Then I should see the edit page
  When I change my language to "<lang_new>"
  Then I should see the language "<lang_new>"

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
