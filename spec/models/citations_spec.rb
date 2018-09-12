describe "Object citations" do
  it "should correctly format a citation" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A test of citations"]
    @t.creator = ["A. Tester"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2015-05-12"]
    @t.type = ["Text"]

    (@t.export_as_dri_citation).should eq("A. Tester. A test of citations, Digital Repository of Ireland [Distributor]")
  end

  it "should add the published year" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A test of citations"]
    @t.creator = ["A. Tester"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2015-05-12"]

    published = Time.now.utc.iso8601
    year = Time.new(published).year 
    @t.published_at = published

    @t.type = ["Text"]

    (@t.export_as_dri_citation).should eq("A. Tester. (#{year}) A test of citations, Digital Repository of Ireland [Distributor]")
  end

  it "should add the depositing institute" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A test of citations"]
    @t.creator = ["A. Tester"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2015-05-12"]

    published = Time.now.utc.iso8601
    year = Time.new(published).year
    @t.published_at = published

    @t.type = ["Text"]

    @c = DRI::Batch.with_standard :qdc
    @c.type = ["Collection"]
    @c.creator = ["A. Collection"] 
    @c.rights = ["Rights"]
    @c.creation_date = ["2015-05-12"]
    @c.depositing_institute = "Depositing Institute"

    @t.governing_collection = @c

    (@t.export_as_dri_citation).should eq("A. Tester. (#{year}) A test of citations, Digital Repository of Ireland [Distributor], Depositing Institute [Depositing Institution]")
  end

end
