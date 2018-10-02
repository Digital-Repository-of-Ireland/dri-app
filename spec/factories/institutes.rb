require 'ffaker'

FactoryBot.define do
  sequence :name do
    FFaker::Name.name
  end
  sequence :domain_name do
    FFaker::Internet.domain_name
  end
end

FactoryBot.define do
  factory(:institute, :class => Institute) do |i|
    i.name { FactoryBot.generate(:name) }
    i.url { FactoryBot.generate(:domain_name) }
  end  
end
