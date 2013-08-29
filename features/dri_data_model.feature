@model
Feature: DRI Data Model

Scenario: DRI Data Model for Audio should not be valid without correct metadata
  Given we have a "DRI::Model::Audio" Model
  When we test an empty "DRI::Model::Audio" Model
  Then the "DRI::Model::Audio" Model should not be valid

Scenario: DRI Data Model for Audio should have correct metadata fields and validate required ones
  Given we have a "DRI::Model::Audio" Model
  When we test the "DRI::Model::Audio" Model
  Then it should validate presence of attribute "title"
  And it should validate presence of attribute "rights"
  #And it should validate presence of attribute "language"
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
  Given we have a "DRI::Model::Pdfdoc" Model
  When we test an empty "DRI::Model::Pdfdoc" Model
  Then the "DRI::Model::Pdfdoc" Model should not be valid

Scenario: DRI Data Model for Pdfdoc should have correct metadata fields and validate required ones
  Given we have a "DRI::Model::Pdfdoc" Model
  When we test the "DRI::Model::Pdfdoc" Model
  Then it should validate presence of attribute "title"
  And it should validate presence of attribute "rights"
  #And it should validate presence of attribute "language"
  And it should have attribute "description"
  And it should have attribute "author"
  And it should have attribute "editor"
  And it should have attribute "creation_date"
  And it should have attribute "subject"
  And it should have attribute "source"
  And it should have attribute "geographical_coverage"
  And it should have attribute "temporal_coverage"

Scenario: DRI Data Model for Collection should not be valid without correct metadata
  Given we have a "DRI::Model::Collection" Model
  When we test an empty "DRI::Model::Collection" Model
  Then the "DRI::Model::Collection" Model should not be valid

Scenario: DRI Data Model for Collection should have correct metadata fields and validate required ones
  Given we have a "DRI::Model::Collection" Model
  When we test the "DRI::Model::Collection" Model
  Then it should validate presence of attribute "title"
  And it should have attribute "description"
  And it should have attribute "publisher"

