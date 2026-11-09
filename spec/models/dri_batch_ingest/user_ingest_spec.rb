require 'rails_helper'

describe DRIBatchIngest::UserIngest, type: :model do

  let(:user) { FactoryBot.build(:collection_manager) }

  it "should accept a user id" do
    expect { described_class.create(user_id: user.id) }.to_not raise_error
  end

  describe "Associations" do
    it { should belong_to(:user) }
    it { should have_many(:batches) }
  end
end
