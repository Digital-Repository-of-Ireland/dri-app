require 'rails_helper'

describe RiiifAuthorizationService do

  before do
    @object = FactoryBot.build(:sound)
    @object[:depositor] = "edituser@dri.ie"
    @object.save

    @generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
    @generic_file.digital_object = @object
    @generic_file.apply_depositor_metadata("edituser@dri.ie")
    @generic_file.save
  end

  it 'should return true for show of published object with public read' do
    @object[:status] = "published"
    @object.read_groups = [SETTING_GROUP_PUBLIC]
    @object.save

    Struct.new("Object", :alternate_id)
    o = Struct::Object.new("alternate_id:#{@generic_file.alternate_id}")

    auth = RiiifAuthorizationService.new(nil)
    expect(auth.can?(:show, o)).to be true
  end

  it 'should return true for info of published object' do
    @object[:status] = "published"
    @object.save

    Struct.new("Object", :alternate_id)
    o = Struct::Object.new("alternate_id:#{@generic_file.alternate_id}")

    auth = RiiifAuthorizationService.new(nil)
    expect(auth.can?(:info, o)).to be true
  end
end

