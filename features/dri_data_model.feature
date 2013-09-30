@model
Feature: DRI Data Model

Scenario: DRI Data Model for Audio should not be valid without correct metadata
  Given we have a "Audio" Model
  When we test an empty "Audio" Model
  Then the "Audio" Model should not be valid

Scenario: DRI Data Model for Audio should have correct metadata fields and validate required ones
  Given we have a "Audio" Model
  When we test the "Audio" Model
  Then it should validate presence of attribute "title"
  And it should validate presence of attribute "rights"
# Metadata Task Force has decided that language is no longer a mandatory field for DRI
# And it should validate presence of attribute "language"
  And it should have attribute "description"
  And it should have attribute "presenter"
  And it should have attribute "guest"
  And it should have attribute "broadcast_date"
  And it should have attribute "creation_date"
  And it should have attribute "subject"
  And it should have attribute "source"
  And it should have attribute "geographical_coverage"
  And it should have attribute "temporal_coverage"

Scenario: DRI Data Model for Pdfdoc should not be valid without correct metadata
  Given we have a "Text" Model
  When we test an empty "Text" Model
  Then the "Text" Model should not be valid

Scenario: DRI Data Model for Pdfdoc should have correct metadata fields and validate required ones
  Given we have a "Text" Model
  When we test the "Text" Model
  Then it should validate presence of attribute "title"
  And it should validate presence of attribute "rights"
# Metadata Task Force has decided that language is no longer a mandatory field for DRI
# And it should validate presence of attribute "language"
  And it should have attribute "description"
  And it should have attribute "author"
  And it should have attribute "editor"
  And it should have attribute "creation_date"
  And it should have attribute "subject"
  And it should have attribute "source"
  And it should have attribute "geographical_coverage"
  And it should have attribute "temporal_coverage"

Scenario: DRI Data Model for Collection should not be valid without correct metadata
  Given we have a "Collection" Model
  When we test an empty "Collection" Model
  Then the "Collection" Model should not be valid

Scenario: DRI Data Model for Collection should have correct metadata fields and validate required ones
  Given we have a "Collection" Model
  When we test the "Collection" Model
  Then it should validate presence of attribute "title"
  And it should have attribute "description"
  And it should have attribute "publisher"

