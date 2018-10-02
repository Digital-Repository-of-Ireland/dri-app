require 'ffaker'

FactoryBot.define do
  sequence :email do
    FFaker::Internet.email
  end
end

FactoryBot.define do
  factory :user, :class => UserGroup::User do |u|
    u.email { FactoryBot.generate(:email) }
    u.password 'password'
    u.password_confirmation 'password'
    u.first_name FFaker::Name.first_name
    u.second_name FFaker::Name.last_name
    u.confirmed_at Time.now
  end

  factory :invalid_user, parent: :user do |u|
    u.email nil
  end

  factory :admin,  parent: :user do |u|
    after(:create) do |user, evaluator|
      @group = UserGroup::Group.find_or_create_by(name: SETTING_GROUP_ADMIN, description: "admin test group")
      @membership = user.join_group(@group.id)
      @membership.approved_by = user.id
      @membership.save
    end
  end

  factory :collection_manager,  parent: :user do |u|
    after(:create) do |user, evaluator|
      @group = UserGroup::Group.find_or_create_by(name: SETTING_GROUP_CM, description: "collection manager test group")
      @membership = user.join_group(@group.id)
      @membership.approved_by = user.id
      @membership.save
    end
  end
end
