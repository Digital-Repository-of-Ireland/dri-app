require 'rails_helper'

describe CitationsHelper, testing: true do

  it "checks if an author name is a personal name" do
    expect(helper.personal_name?('Arthur Test')).to be true
    expect(helper.personal_name?('Digital Repository of Ireland')).to be false
  end

  it "should return organisation names as literals" do
    parsed_author = helper.get_one_author("Digital Repository of Ireland")
    expect(parsed_author.key?("literal")).to be true
    expect(parsed_author['literal']).to eq('Digital Repository of Ireland')
  end

  it "should parse personal names" do
    first_name = 'Arthur'
    last_name = 'Tester'
    parsed_author = helper.get_one_author(first_name + ' ' + last_name)
    expect(parsed_author['family']).to eq(last_name)
    expect(parsed_author['given']).to eq(first_name)
  end

  it "should handle names with quote" do
    first_name = 'Arthur'
    last_name = "D'Amore"
    parsed_author = helper.get_one_author(first_name + ' ' + last_name)
    expect(parsed_author['family']).to eq("D'Amore")
    expect(parsed_author['given']).to eq(first_name)
  end

  it "can handle multiple authors" do
    expect(helper.get_authors(["Arthur Tester", "Digital Repository of Ireland"]).length).to eq 2
  end

  describe "citation formats" do
    let(:object) do
      object = DRI::DigitalObject.with_standard :qdc
      object.title = ["A test of citations"]
      object.creator = ["A. Tester"]
      object.rights = ["Rights"]
      object.creation_date = ["2015-05-12"]

      published = "2021-11-24T15:00:00Z"
      year = Time.parse(published).year
      object.published_at = published
      object.type = ["Text"]

      object
    end

    it "renders an APA citation" do
      expect(helper.export_as_apa_citation(object, "10.7486/DRI.XXXXX", "Depositing Institute")).to eq("A. Tester. (2021, November 24). A test of citations. Digital Repository of Ireland; Depositing Institute. https://doi.org/10.7486/DRI.XXXXX")
    end

    it "renders an MLA citation" do
      expect(helper.export_as_mla_citation(object, "10.7486/DRI.XXXXX", "Depositing Institute")).to eq("A. Tester. “A Test of Citations.” Digital Repository of Ireland, Depositing Institute, 24 Nov. 2021, doi:10.7486/DRI.XXXXX.")
    end

    it "renders a Chicago citation" do
      expect(helper.export_as_chicago_citation(object, "10.7486/DRI.XXXXX", "Depositing Institute")).to eq("A. Tester. “A Test of Citations.” Digital Repository of Ireland. Depositing Institute, November 24, 2021. https://doi.org/10.7486/DRI.XXXXX.")
    end
  end
end
