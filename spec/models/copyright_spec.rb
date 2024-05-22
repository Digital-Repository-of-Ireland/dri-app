require 'rails_helper'

describe Copyright do
  before(:each) do
    @copyright = Copyright.new(
      name: 'test copyright', description: 'this is a copyright test', url: 'http://copyright.example.com'
    )
    @copyright.save
  end
  after(:each) do
    @copyright.destroy
  end
  describe 'show' do
    it 'should return a limited hash representation of the object' do
      expect(@copyright.show.keys.sort).to eq %w[description name url]
    end
  end

  describe 'label' do
    it 'should return name if no url' do
      l = Copyright.new(name: 'nosurl', description: 'no url', url: '')
      expect(l.label).to eq l.name
    end

    it 'should return url if present' do
      l = Copyright.new(name: 'url', description: 'url', url: 'http://copyright.url')
      expect(l.label).to eq l.url
    end  
  end
end
