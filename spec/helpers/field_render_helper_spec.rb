describe FieldRenderHelper, testing: true do

  describe "field_value_separator" do
    it "returns a blank" do
      expect(helper.field_value_separator()).to eq('')
    end
  end

  describe "render_description" do
    it "has no metadata toggle if all no language set" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      expect(helper.render_description({:field => 'description_tesim',
       :document => {'description_tesim' => ['Sample Description']}})).to_not include('Hide Irish', 'Hide English')
    end

    it "adds a default link to hide GA for irish metadata" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      expect(helper.render_description({:field => 'description_gle_tesim',
        :document => {'description_gle_tesim' => ['Sample Description']}})).to include('Hide Irish')
    end

    it "adds a default link to hide EN for English metadata" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      expect(helper.render_description({:field => 'description_eng_tesim',
        :document => {'description_eng_tesim' => ['Sample Description'],
        'description_gle_tesim' => []}})).to include('Hide English')
    end

    it "when metadata language is ga there is a link to hide irish metadata" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      helper.request.cookies[:metadata_language] = "ga"
      expect(helper.render_description({:field => 'description_gle_tesim',
        :document => {'description_gle_tesim' => ['Sample Description']}})).to include('Hide Irish')
      helper.request.cookies[:metadata_language] = "en"
    end

    it "when metadata language is ga there is a link to show English metadata" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      helper.request.cookies[:metadata_language] = "ga"
      expect(helper.render_description({:field => 'description_eng_tesim',
        :document => {'description_eng_tesim' => ['Sample Description'],
        'description_gle_tesim' => []}})).to include('Show English')
      helper.request.cookies[:metadata_language] = "en"
    end

    it "when metadata language is en there is a link to hide irish metadata" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      helper.request.cookies[:metadata_language] = "en"
      expect(helper.render_description({:field => 'description_gle_tesim',
        :document => {'description_gle_tesim' => ['Sample Description']}})).to include('Show Irish')
    end

    it "when metadata language is en there is a link to show English metadata" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :en
      helper.request.cookies[:metadata_language] = "en"
      expect(helper.render_description({:field => 'description_eng_tesim',
        :document => {'description_eng_tesim' => ['Sample Description'],
        'description_gle_tesim' => []}})).to include('Hide English')
    end

    it "should work whether Irish or English display language is set" do
      controller.request = ActionController::TestRequest.new(:fullpath => '/my_collections/6q182k12h')
      I18n.locale = :ga
      helper.request.cookies[:metadata_language] = "en"
      expect(helper.render_description({:field => 'description_eng_tesim',
        :document => {'description_eng_tesim' => ['Sample Description'],
        'description_gle_tesim' => []}})).to include('Folaigh an Béarla')
      I18n.locale = :en
    end

  end


  describe "parse_description" do

    it "it will return single desc with no paragraph separator" do
      expect(helper.parse_description({:field => 'description_tesim',
         :document => {'description_tesim' => ['Sample Description']}})).to eq('<p>Sample Description</p>')
    end

    it "it will return multiple desc with paragraph separator" do
      expect(helper.parse_description({:field => 'description_tesim',
         :document => {'description_tesim' => ['Sample Description 1', 'Sample Description 2']}}).last).to eq('<p>Sample Description 2</p>')
    end
  end

  describe "standardise_value" do

    it "will parse DCMI encoded temporal coverage" do
      expect(standardise_value({:facet_name => 'temporal_coverage_sim',
        :value => 'name=Early 20th Century; start=1900-01-01; end=1949-12-31;'})).to eq('Early 20th Century')
    end

    it "will parse DCMI encoded geographical coverage" do
      expect(standardise_value({:facet_name => 'geographical_coverage_sim',
        :value => 'name=Magheracar; east=-8.2730672; north=54.471214;'})).to eq('Magheracar')
    end

    it "will do nothing with other fields" do
    end
  end

  describe "get_value_from_solr_field" do
    it "will return the requested part of DCMI encoded temporal field" do
      expect(get_value_from_solr_field('name=Early 20th Century; start=1900-01-01; end=1949-12-31;','name')).to eq('Early 20th Century')
    end

    it "will return the requested part of DCMI encoded spatial field" do
      expect(get_value_from_solr_field('name=The 1960s; start=1960-01-01; end=1969-12-31','name')).to eq('The 1960s')
    end

    it "will work for other parts aside from names" do
      expect(get_value_from_solr_field('name=Early 20th Century; start=1900-01-01; end=1949-12-31;','end')).to eq('1949-12-31')
    end

    it "will return the original string if it can't be parsed" do
      expect(get_value_from_solr_field('this is not a DCMI field','name')).to eq('this is not a DCMI field')
    end

    it "will return nil if it can't find the requested field" do
      expect(get_value_from_solr_field('name=Early 20th Century; start=1900-01-01','end')).to be_nil
    end

  end
end
