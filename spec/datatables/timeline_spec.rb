describe 'Timeline' do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
      
    @object = FactoryBot.create(:sound) 
    @object[:status] = "draft"
    @object.save
  end

  after(:each) do
    @object.delete
    FileUtils.remove_dir(@tmp_assets_dir, :force => true)
  end


  it 'should get the minimum and maximum dates from range' do
    @object.creation_date = [ 'name=90s;start=1990-01-01;end=1999-12-31', 'name=80s;start=1980-01-01;end=1989-12-31']
    @object.save

    @object.reload

    ts = Timeline.new(ActionController::Base.new.view_context)
    dates = ts.document_date(SolrDocument.new(@object.to_solr), 'cdate')
    expect(dates[0].to_s).to eq('1980-01-01T00:00:00+00:00')
    expect(dates[1].to_s).to eq('1999-12-31T00:00:00+00:00')
  end

  it 'should work with single dates' do
    @object.creation_date = [ '1990-01-01', '1980-01-01']
    @object.save

    @object.reload

    ts = Timeline.new(ActionController::Base.new.view_context)
    dates = ts.document_date(SolrDocument.new(@object.to_solr), 'cdate')
    expect(dates[0].to_s).to eq('1980-01-01T00:00:00+00:00')
    expect(dates[1].to_s).to eq('1990-01-01T00:00:00+00:00')
  end

  it 'should include months' do
    @object.creation_date = [ '1990-10-01', '1990-07-01']
    @object.save

    @object.reload

    ts = Timeline.new(ActionController::Base.new.view_context)
    dates = ts.document_date(SolrDocument.new(@object.to_solr), 'cdate')
    expect(dates[0].to_s).to eq('1990-07-01T00:00:00+00:00')
    expect(dates[1].to_s).to eq('1990-10-01T00:00:00+00:00')
  end

end
