require 'ffaker'

FactoryBot.define do
  # ensure name and domain_name are unique for every new institute
  sequence :name do
    FFaker::Name.name
  end
  sequence :domain_name do
    FFaker::Internet.domain_name
  end
end

FactoryBot.define do
  factory(:institute, class: Institute) do |i|
    i.name       { FactoryBot.generate(:name) }
    i.url        { FactoryBot.generate(:domain_name) }
    i.logo       { 'fake_logo.png' }
    i.depositing { true }
  end  
end
