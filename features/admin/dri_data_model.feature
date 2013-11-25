@model
Feature: DRI Data Model

Scenario: DRI Data Model for Sound should not be valid without correct metadata
  Given we have a "Sound" Model
  When we test an empty "Sound" Model
  Then the "Sound" Model should not be valid

Scenario: DRI Data Model for Sound should have correct metadata fields and validate required ones
  Given we have a "Sound" Model
  When we test the "Sound" Model
  Then it should validate presence of attribute "title"
  And it should validate presence of attribute "rights"
  And it should validate presence of attribute "description"
  And it should validate presence of attribute "type"
  And it should have attribute "language"
  And it should have attribute "role_hst"
  And it should have attribute "contributor"
  And it should have attribute "published_date"
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
  And it should validate presence of attribute "description"
  And it should validate presence of attribute "type"
  And it should have attribute "language"
  And it should have attribute "role_aut"
  And it should have attribute "role_edt"
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
  And it should validate presence of attribute "description"
  And it should validate presence of attribute "rights"
  And it should validate presence of attribute "type"
  And it should have attribute "publisher"

