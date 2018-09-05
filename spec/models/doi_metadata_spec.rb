describe DoiMetadata do

  it "should get the publication year" do
    datacite = DoiMetadata.new
    expect(datacite.publication_year).to equal(Time.now.year)
  end

end
