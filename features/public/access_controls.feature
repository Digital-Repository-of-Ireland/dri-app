Feature: Access controls
  In order to control access to digital objects and assets
  I should be able to set permissions by user and group
  And to inherit permissions

Scenario: I should see the asset file where masterfile is accesible and object is public read
  Given a collection with pid "dri:c11111" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o11111" and title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o11111" is governed by the collection with pid "dri:c11111"
  And the object with pid "dri:o11111" has "accessible" masterfile
  And the object with pid "dri:o11111" is publicly readable
  And the object with pid "dri:c11111" is published
  And the object with pid "dri:o11111" is published
  When I go to "show Digital Object page for id dri:o11111"
  Then I should see a link to download asset
  And I should not see a link to download surrogate

Scenario: I should not see the asset file if it is under embargo
  Given a collection with pid "dri:c22222" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o22222" and title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o22222" is governed by the collection with pid "dri:c22222"
  And the object with pid "dri:o22222" has "accessible" masterfile
  And the object with pid "dri:c22222" is published
  And the object with pid "dri:o22222" is published
  And the object with pid "dri:o22222" is under embargo
  When I go to "show Digital Object page for id dri:o22222"
  Then I should not see a link to download asset
  And I should not see a link to download surrogate
  And I should see "You do not have permission"

@random_pid @ceph @public-broken
Scenario: I should see the surrogate when the master file is not accessible
  Given a collection with pid "dri:c33333" and title "Access Controls Test Collection" created by "user1"
  And the collection with title "Access Controls Test Collection" is published
  And a Digital Object with pid "dri:o33333", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o33333" is governed by the collection with pid "dri:c33333"
  And the object with pid "dri:o33333" is publicly readable
  And the object with pid "dri:o33333" has "inaccessible" masterfile
  And the object with pid "dri:o33333" has a deliverable surrogate file
  And the object with pid "dri:o33333" is published
  And I am not logged in
  When I go to "show Digital Object page for id dri:o33333"
  Then I should see a link to download surrogate
  And I should not see a link to download asset

@public-broken
Scenario: I should see no files message when master file is not accessible and surrogates not yet created
  Given a collection with pid "dri:c44444" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o44444", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o44444" is governed by the collection with pid "dri:c44444"
  And the object with pid "dri:o44444" is publicly readable
  And the object with pid "dri:o44444" has "inaccessible" masterfile
  And the object with pid "dri:c44444" is published
  And the object with pid "dri:o44444" is published
  And I am not logged in
  When I go to "show Digital Object page for id dri:o44444"
  Then I should not see a link to download asset
  And I should not see a link to download surrogate
  And I should see "No file has been uploaded"

Scenario Outline: When I do have access by group or id then I should see the asset file
  Given a collection with pid "dri:c55555" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o55555", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o55555" is governed by the collection with pid "dri:c55555"
  And the object with pid "dri:o55555" has "accessible" masterfile
  And the object with pid "dri:o55555" has permission "<access>" for "<entity>" "<id>"
  And the object with pid "dri:c55555" is published
  And the object with pid "dri:o55555" is published
  And I am logged in as "user2" in the group "mygroup"
  When I go to "show Digital Object page for id dri:o55555"
  Then I should see a link to download asset
  And I should not see a link to download surrogate

Examples:
  | entity | access           | id      |
  | group  | read access      | mygroup |
  | user   | read access      | user2   |
  | group  | inherited access | mygroup |
  | user   | inherited access | user2   |

@public-broken
Scenario: When I do not have access by group or id then I should not see the asset file
  Given a collection with pid "dri:c66666" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o66666", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o66666" is governed by the collection with pid "dri:c66666"
  And the object with pid "dri:o66666" has "accessible" masterfile
  And the object with pid "dri:o66666" has no read access for my user
  And the object with pid "dri:o66666" has no read access for my group
  And the object with pid "dri:c66666" is published
  And the object with pid "dri:o66666" is published
  And I am logged in as "user2" in the group "unprivileged"
  When I go to "show Digital Object page for id dri:o66666"
  Then I should not see a link to download asset
  And I should not see a link to download surrogate
  And I should see "You do not have permission"

Scenario: I should not see an object that is in draft status
  Given a collection with pid "dri:c77777" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o77777", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o77777" is governed by the collection with pid "dri:c77777"
  And the object with pid "dri:o77777" has "accessible" masterfile
  And the object with pid "dri:o77777" is publicly readable
  And the object with pid "dri:c77777" is published
  When I go to "show Digital Object page for id dri:o77777"
  Then I should not see a link to download asset
  And I should not see a link to download surrogate
  And I should see "Unauthorized"

Scenario: I should see the object in search when it is public discoverable (metadata)
  Given a collection with pid "dri:c88888" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o88888", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o88888" is governed by the collection with pid "dri:c88888"
  And the object with pid "dri:o88888" has "inaccessible" masterfile
  And the object with pid "dri:o88888" has no read access for my user
  And the object with pid "dri:o88888" has no read access for my group
  And the object with pid "dri:o88888" has public discover access and metadata
  And the object with pid "dri:c88888" is published
  And the object with pid "dri:o88888" is published
  And I am logged in as "user2" in the group "unprivileged"
  When I go to "the home page"
  And I fill in "q" with "Access"
  And I press the button to search
  Then I should see a search result "Access Controls Test Object"

Scenario: I should not see the object in search when it is published but parent collection is draft
  Given a collection with pid "dri:c99999" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o99999", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o99999" is governed by the collection with pid "dri:c99999"
  And the object with pid "dri:o99999" has "inaccessible" masterfile
  And the object with pid "dri:o99999" has no read access for my user
  And the object with pid "dri:o99999" has no read access for my group
  And the object with pid "dri:o99999" has public discover access and metadata
  And the object with pid "dri:o99999" is published
  And I am logged in as "user2" in the group "unprivileged"
  When I go to "the home page"
  And I fill in "q" with "Access"
  And I press the button to search
  Then I should not see a search result "Access Controls Test Object"

Scenario: I should not see the object when the parent collection is draft
  Given a collection with pid "dri:c77777" and title "Access Controls Test Collection" created by "user1"
  And a Digital Object with pid "dri:o77777", title "Access Controls Test Object" created by "user1"
  And the object with pid "dri:o77777" is governed by the collection with pid "dri:c77777"
  And the object with pid "dri:o77777" has "accessible" masterfile
  And the object with pid "dri:o77777" is publicly readable
  And the object with pid "dri:o77777" is published
  When I go to "show Digital Object page for id dri:o77777"
  Then I should not see a link to download asset
  And I should not see a link to download surrogate
  And I should see "Unauthorized"

