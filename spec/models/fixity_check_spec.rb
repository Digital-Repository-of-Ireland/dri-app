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

  it 'should return the latest checks' do
    latest = FixityCheck.where(collection_id: 'test').latest
    expect(latest.to_a.count).to be 2

    expect(latest.first.created_at.to_s).to eq('2018-03-29 10:51:27 UTC')
    expect(latest.last.created_at.to_s).to eq('2018-03-29 10:52:27 UTC')
  end

  it 'should return failed checks' do
    failed = FixityCheck.where(collection_id: 'test').failed
    expect(failed.to_a.count).to be 1

    expect(failed.first.created_at.to_s).to eq('2018-03-29 10:51:27 UTC')
  end

end
