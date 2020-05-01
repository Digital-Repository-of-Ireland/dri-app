require 'rails_helper'

describe IngestStatus do

  before(:each) do
    @ingest_status = IngestStatus.create(batch_id: 'test-1', asset_id: 'asset-1', status: 'processing')
  end

  after(:each) do
    @ingest_status.delete
  end

  it 'should return the correct completed status if there is a failed job' do
    @ingest_status.asset_type = 'image'
    job_status = JobStatus.create(job: 'thumbnail', status: 'failed')
    @ingest_status.job_status << job_status
    @ingest_status.save

    expect(@ingest_status.completed_status).to eq 'error'
  end

  it 'should return the correct completed status if success' do
    @ingest_status.asset_type = 'image'
    job_status = JobStatus.create(job: 'thumbnail', status: 'success')
    @ingest_status.job_status << job_status
    @ingest_status.save

    expect(@ingest_status.completed_status).to eq 'success'
  end

  it 'should not be completed if no errors and queue not finished' do
    @ingest_status.asset_type = 'image'
    job_status = JobStatus.create(job: 'characterize', status: 'success')
    @ingest_status.job_status << job_status
    job_status = JobStatus.create(job: 'create_bucket', status: 'success')
    @ingest_status.job_status << job_status
    @ingest_status.save

    @ingest_status.completed?(job_status)

    expect(@ingest_status.status).to eq 'processing'
  end

  it 'should complete with error if characterize fails' do
    @ingest_status.asset_type = 'image'
    job_status = JobStatus.create(job: 'characterize', status: 'failed')
    @ingest_status.job_status << job_status
    @ingest_status.save

    @ingest_status.completed?(job_status)

    expect(@ingest_status.status).to eq 'error'
  end

  it 'should be completed with success if no failures' do
    @ingest_status.asset_type = 'image'
    @ingest_status.job_status << JobStatus.create(job: 'characterize', status: 'success')
    @ingest_status.job_status << JobStatus.create(job: 'create_bucket', status: 'success')
    job_status = JobStatus.create(job: 'thumbnail', status: 'success')
    @ingest_status.job_status << job_status
    @ingest_status.save

    @ingest_status.completed?(job_status)
    expect(@ingest_status.status).to eq 'success'
  end

  it 'should be completed with success if earlier failures' do
    @ingest_status.asset_type = 'image'
    @ingest_status.job_status << JobStatus.create(job: 'characterize', status: 'failed')
    @ingest_status.job_status << JobStatus.create(job: 'characterize', status: 'success')
    @ingest_status.job_status << JobStatus.create(job: 'create_bucket', status: 'success')
    job_status = JobStatus.create(job: 'thumbnail', status: 'success')
    @ingest_status.job_status << job_status
    @ingest_status.save

    expect(@ingest_status.completed_status).to eq 'success'
  end

  it 'should be completed with error if failures' do
    @ingest_status.asset_type = 'image'
    @ingest_status.job_status << JobStatus.create(job: 'characterize', status: 'success')
    @ingest_status.job_status << JobStatus.create(job: 'create_bucket', status: 'success')
    job_status = JobStatus.create(job: 'thumbnail', status: 'failed')
    @ingest_status.job_status << job_status
    @ingest_status.save

    @ingest_status.completed?(job_status)
    expect(@ingest_status.status).to eq 'error'
  end

  it 'should be completed with error if laterfailure' do
    @ingest_status.asset_type = 'image'
    @ingest_status.job_status << JobStatus.create(job: 'characterize', status: 'success')
    @ingest_status.job_status << JobStatus.create(job: 'characterize', status: 'failed')
    @ingest_status.job_status << JobStatus.create(job: 'create_bucket', status: 'success')
    job_status = JobStatus.create(job: 'thumbnail', status: 'failed')
    @ingest_status.job_status << job_status
    @ingest_status.save

    expect(@ingest_status.completed_status).to eq 'error'
  end
end
