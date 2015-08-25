require 'spec_helper'

describe DoiMetadata do

  it "should get the publication year" do
    datacite = DoiMetadata.new
    datacite.publication_year.should equal(Time.now.year)
  end

end
