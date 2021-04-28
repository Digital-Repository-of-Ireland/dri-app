require 'rails_helper'

feature 'Relating objects' do
  describe 'as a manager user' do
    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:collection_manager)

      visit user_group.new_user_session_path
      fill_in "user_email", with: @login_user.email
      fill_in "user_password", with: @login_user.password
      click_button "Login"
    end

    after(:each) do
      @login_user.destroy
      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    scenario 'relate objects in different collections' do
      collection_a = FactoryBot.create(:collection)
      collection_a.depositor = User.find_by_email(@login_user.email).to_s
      collection_a.manager_users_string=User.find_by_email(@login_user.email).to_s
      collection_a.discover_groups_string="public"
      collection_a.read_groups_string="registered"
      collection_a.creator = [@login_user.email]

      object_a = FactoryBot.create(:sound)
      object_a.depositor=User.find_by_email(@login_user.email).to_s
      object_a.manager_users_string=User.find_by_email(@login_user.email).to_s
      object_a.creator = [@login_user.email]
      object_a.identifier = "OBJECT_A"
      object_a.save

      collection_a.governed_items << object_a
      collection_a.save

      collection_b = FactoryBot.create(:collection)
      collection_b.depositor = User.find_by_email(@login_user.email).to_s
      collection_b.manager_users_string=User.find_by_email(@login_user.email).to_s
      collection_b.discover_groups_string="public"
      collection_b.read_groups_string="registered"
      collection_b.creator = [@login_user.email]

      object_b = FactoryBot.create(:sound)
      object_b.depositor=User.find_by_email(@login_user.email).to_s
      object_b.manager_users_string=User.find_by_email(@login_user.email).to_s
      object_b.creator = [@login_user.email]
      object_b.relation_ids_relation = "OBJECT_A"
      object_b.save

      collection_b.governed_items << object_b
      collection_b.save

      related = collection_b.collection_relationships.build(collection_relative_id: collection_a.id)
      related.save
      collection_b.reload
      collection_b.update_index
      visit(my_collections_path(object_b.alternate_id))
      expect(page).to have_link(href: my_collections_path(object_a.alternate_id))

      collection_a.delete
      collection_b.delete
    end

    scenario 'relate objects in same collection' do
      collection_a = FactoryBot.create(:collection)
      collection_a.depositor = User.find_by_email(@login_user.email).to_s
      collection_a.manager_users_string=User.find_by_email(@login_user.email).to_s
      collection_a.discover_groups_string="public"
      collection_a.read_groups_string="registered"
      collection_a.creator = [@login_user.email]

      object_a = FactoryBot.create(:sound)
      object_a.depositor=User.find_by_email(@login_user.email).to_s
      object_a.manager_users_string=User.find_by_email(@login_user.email).to_s
      object_a.creator = [@login_user.email]
      object_a.identifier = "OBJECT_A"
      object_a.save

      object_b = FactoryBot.create(:sound)
      object_b.depositor=User.find_by_email(@login_user.email).to_s
      object_b.manager_users_string=User.find_by_email(@login_user.email).to_s
      object_b.creator = [@login_user.email]
      object_b.relation_ids_relation = "OBJECT_A"
      object_b.save

      collection_a.governed_items << object_a
      collection_a.governed_items << object_b
      collection_a.save

      visit(my_collections_path(object_b.alternate_id))
      expect(page).to have_link(href: my_collections_path(object_a.alternate_id))

      collection_a.delete
    end
  end
end
