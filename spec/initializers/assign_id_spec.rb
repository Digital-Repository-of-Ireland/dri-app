require 'spec_helper'

describe 'assign_id' do

  context 'id does not exist' do
    
    it 'should be valid' do
      expect(DRI::Batch.new.id_valid?('test')).to be true
    end
  end

  context 'id already exists' do

    it 'should be invalid' do
      object = FactoryGirl.create(:sound)
      
      expect(DRI::Batch.new.id_valid?(object.id)).to be false
    end
  end

  context 'id is a tombstone' do

    it 'should be invalid' do
      object = FactoryGirl.create(:sound)
      object.delete

      expect(DRI::Batch.new.id_valid?(object.id)).to be false
    end
  end

  context 'limited attempts' do

    it 'should run out of attempts' do
      DRI::Batch.any_instance.stub(:id_valid?).and_return(false)
      batch = DRI::Batch.new
      expect(batch.new_id).to be nil
    end
 end
    
end  
