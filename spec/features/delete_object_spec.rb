require 'spec_helper'

feature 'Deleting a single object' do
  
  before(:each) do
    @login_user = FactoryGirl.create(:admin)

    visit new_user_session_path
    fill_in "user_email", with: @login_user.email
    fill_in "user_password", with: @login_user.password
    click_button "Login"
  end

  after(:each) do
    @login_user.delete
  end

  scenario 'unable to delete a published object' do
    collection = FactoryGirl.create(:collection)
   
    object = FactoryGirl.create(:sound) 
    object[:status] = "published"
    object.save

    collection.governed_items << object
  
    visit(object_path(object.id))

    expect(page).not_to have_link(I18n.t('dri.views.objects.buttons.delete_object'))

    collection.delete
 end

  scenario 'deleting a draft object' do
    collection = FactoryGirl.create(:collection)
   
    object = FactoryGirl.create(:sound) 
    object[:status] = "draft"
    object.save

    collection.governed_items << object
  
    visit(object_path(object.id))
    click_button "delete_object_#{object.id}"

    expect(current_path).to eq(root_path)
    expect(page.find('.dri_alert_text')).to have_content I18n.t('dri.flash.notice.object_deleted')

    collection.reload
    collection.delete
 end

end
    
