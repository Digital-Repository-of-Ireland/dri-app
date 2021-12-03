require 'rails_helper'

describe FixityCheck do

  before(:each) do
    FixityCheck.create(collection_id: 'test', object_id: 'test_object1', created_at: '2018-03-28 10:50:27', verified: true)
    FixityCheck.create(collection_id: 'test', object_id: 'test_object2', created_at: '2018-03-28 10:51:27', verified: true)
    FixityCheck.create(collection_id: 'test', object_id: 'test_object1', created_at: '2018-03-29 10:51:27', verified: false)
    FixityCheck.create(collection_id: 'test', object_id: 'test_object2', created_at: '2018-03-29 10:52:27', verified: true)
  end

  after(:each) do
    FixityCheck.where(collection_id: 'test').delete_all
  end

  it 'should return failed checks' do
    failed = FixityCheck.where(collection_id: 'test').failed
    expect(failed.to_a.count).to be 1

    expect(failed.first.created_at.to_s).to eq('2018-03-29 10:51:27 UTC')
  end

  it 'should geneate premis XML' do
    check = FixityCheck.first
    check.result = "{}"
    expect(Nokogiri::XML(check.to_premis).errors).to be_empty
  end
end
