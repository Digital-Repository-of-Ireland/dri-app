require 'rails_helper'

describe Licence do
  before(:each) do
    @licence = Licence.new(
      name: 'test', description: 'this is a test', url: 'http://exaample.com'
    )
    @licence.save
  end
  after(:each) do
    @licence.destroy
  end
  describe 'show' do
    it 'should return a limited hash representation of the object' do
      # ruby hashes aren't ordered, sort to ensure match
      expect(@licence.show.keys.sort).to eq %w[description name url]
    end
  end

  describe 'label' do
    it 'should return name if no url' do
      l = Licence.new(name: 'nourl', description: 'no url', url: '')
      expect(l.label).to eq l.name
    end

    it 'should return url if present' do
      l = Licence.new(name: 'url', description: 'url', url: 'http://licence.url')
      expect(l.label).to eq l.url
    end  
  end
end
