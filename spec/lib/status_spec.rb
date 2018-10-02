describe 'Status' do

  let(:dummy_class) { Class.new { 
    include BackgroundTasks::Status

    def generic_file
      Class.new { 
        def batch
          Class.new {
            def id
              'test-1'
            end
          }.new
        end
      }.new
    end

    def generic_file_id
      'asset-1'
    end
    }
  }

  it 'should set the status success if no failure' do
    dummy = dummy_class.new
    dummy.with_status_update('test') do
      true
    end

    expect(dummy.status.job_status.first.status).to eq 'success'
  end

  it 'should set the status failed if failure' do
    dummy = dummy_class.new
    dummy.with_status_update('test') do
      raise "error"
    end

    expect(dummy.status.job_status.first.status).to eq 'failed'
  end
end
