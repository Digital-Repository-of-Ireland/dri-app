require "rails_helper"

RSpec.describe "Collection config", type: :feature do

  context 'Allowing exports to signed in users' do

    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:user)
      @collection = FactoryBot.create(:collection)
      @collection.status = 'published'
      @collection.save
      @config = CollectionConfig.create(collection_id: @collection.alternate_id)
      visit user_group.new_user_session_path
      fill_in "user_email", with: @login_user.email
      fill_in "user_password", with: @login_user.password
      click_button "Login"
    end

    after(:each) do
      @config.destroy
      @collection.destroy
      @login_user.destroy
      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it "should not show export link if config does not exist" do
      @config.destroy
      visit(catalog_path(@collection.alternate_id))

      expect(page).not_to have_css('a#export_metadata')
    end

    it "should not show export link if not allowed in config" do
      @config.allow_export = false
      @config.save
      visit(catalog_path(@collection.alternate_id))

      expect(page).not_to have_css('a#export_metadata')
    end

    it "should show export link if allowed in config" do
      @config.allow_export = true
      @config.save
      visit(catalog_path(@collection.alternate_id))

      expect(page).to have_css('a#export_metadata')
    end

    it "should show export link if user can edit" do
      @collection.edit_users_string=User.find_by_email(@login_user.email).to_s
      @collection.save
      visit(catalog_path(@collection.alternate_id))

      expect(page).to have_css('a#export_metadata')
    end
  end
end