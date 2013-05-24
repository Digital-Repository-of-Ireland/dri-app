@public @req-33 @javascript
Feature: Social Media

DELETEME: REQ-33
DELETEME: 
DELETEME: The system must support the use of social media
DELETEME: 
DELETEME: 1.1 It shall display social media "follow" buttons (e.g. follow us on Twitter).
DELETEME: 1.2 It may display social media sharing "buttons" for open content only.
DELETEME: 1.2.1 It shall remove social media sharing "buttons" for restricted content.
DELETEME: 1.2.2 It may allow users to share (a link) to a digital object on social media sites in accordance with access rights.
DELETEME: 1.3 It may allow users social tagging in accordance with access rights

In order to reuse data in social media systems
As a user that can view digital objects
I want to be able to share the digital objects metadata

Scenario: The DRI repository shall display social media "follow" buttons (e.g. follow us on Twitter)
  When I go to "the home page"
  Then I should see the iframe "twitter-widget-0"

# Tests that as the depositor (who obviously has permissions), I can share
# the content. This may not be what we want to test, but it actually runs
# and passes now. See the test below for restricted content for how we might
# rewrite this when we have implemented content restrictions
Scenario: Viewing a Digital Object may display social media sharing "buttons" for open content only.
  Given a Digital Object with pid "dri:obj1" and title "A Test Object"
  When I go to the "object" "show" page for "dri:obj1"
  Then I should see a section with id "socialmedia"

# This won't pass as functionality is not yet implemented
Scenario: Social media "buttons" should not be shown for restricted content.
  Given a Digital Object with pid "dri:obj1" and title "A Test Object"
  When I set the permissions for object "dri:obj1" to restricted
  And I go to the "object" "show" page for "dri:obj1"
  Then I should see a section with id "socialmedia"
  When I follow the link to sign out
  And I go to the "object" "show" page for "dri:obj1"
  Then I should not see a section with id "socialmedia"

# similar to above, it repeats, same as social tagging
# I don't think it's the same as above. The above refers to the button's existance on the page
# this item refers to the actual sharing/liking. I.e. that when you click on the buttons the
# link will be shared on your social media profile.
# This has been tested manually once and it is not desirable to add automatic tests for this
# as without extensive stubbing, it would involve creating test accounts on real social media
# sites and posting test links to potentially publicly viewable profiles. It is also not necessary
# for us to test functionality and code provided by Google, Facebook, etc.
Scenario: Allow users to share (a link) to a digital object on social media sites in accordance with access rights.

# similar to above, it repeats, define social tagging
Scenario: It may allow users social tagging in accordance with access rights.
