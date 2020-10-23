require 'rails_helper'

RSpec.describe FixityReport, type: :model do
  before(:each) do
    FixityReport.create(collection_id: 'test', created_at: '2018-03-28 10:50:27')
    FixityReport.create(collection_id: 'test', created_at: '2018-03-28 10:51:27')
    FixityReport.create(collection_id: 'test', created_at: '2018-03-29 10:51:27')
    FixityReport.create(collection_id: 'test', created_at: '2018-03-29 10:52:27')
  end

  after(:each) do
    FixityReport.where(collection_id: 'test').delete_all
  end

  it 'should return the latest checks' do
    latest = FixityReport.where(collection_id: 'test').latest

    expect(latest.created_at.to_s).to eq('2018-03-29 10:52:27 UTC')
  end
end
