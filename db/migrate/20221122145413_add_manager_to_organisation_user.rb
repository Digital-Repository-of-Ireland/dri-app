class AddManagerToOrganisationUser < ActiveRecord::Migration[6.1]
  def change
    add_column :organisation_users, :manager, :boolean
  end
end
