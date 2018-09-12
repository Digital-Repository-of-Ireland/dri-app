require 'ostruct'
require 'resque-status'

describe 'StatusJob' do
	
   describe 'run' do

     it 'should return call update with completed counts' do
       allow_any_instance_of(StatusJob).to receive(:retrieve_status).and_return(
                     [['test1', OpenStruct.new({ status: 'completed' })],['test2', OpenStruct.new({ status: 'completed' })]])

       job = StatusJob.new('test')

       expect(job).to receive(:update_status).once.ordered.with('test', 2, 1)
       expect(job).to receive(:update_status).once.ordered.with('test', 2, 2)
       job.wait_for_completion('test', ['test1', 'test2'])
     end

   end

end
