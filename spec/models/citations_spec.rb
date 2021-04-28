require 'rails_helper'

describe "Object citations" do
  it "should correctly format a citation" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A test of citations"]
    @t.creator = ["A. Tester"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2015-05-12"]
    @t.type = ["Text"]

    expect(@t.export_as_dri_citation).to eq("A. Tester. A test of citations, Digital Repository of Ireland [Distributor]")
  end

  it "should add the published year" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A test of citations"]
    @t.creator = ["A. Tester"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2015-05-12"]

    published = Time.now.utc.iso8601
    year = Time.new(published).year 
    @t.published_at = published

    @t.type = ["Text"]

    expect(@t.export_as_dri_citation).to eq("A. Tester. (#{year}) A test of citations, Digital Repository of Ireland [Distributor]")
  end

  it "should add the depositing institute" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A test of citations"]
    @t.creator = ["A. Tester"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2015-05-12"]

    published = Time.now.utc.iso8601
    year = Time.new(published).year
    @t.published_at = published

    @t.type = ["Text"]

    @c = DRI::DigitalObject.with_standard :qdc
    @c.type = ["Collection"]
    @c.creator = ["A. Collection"] 
    @c.rights = ["Rights"]
    @c.creation_date = ["2015-05-12"]
    @c.depositing_institute = "Depositing Institute"

    @t.governing_collection = @c

    expect(@t.export_as_dri_citation).to eq("A. Tester. (#{year}) A test of citations, Digital Repository of Ireland [Distributor], Depositing Institute [Depositing Institution]")
  end

end
