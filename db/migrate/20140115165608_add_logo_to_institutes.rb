class AddLogoToInstitutes < ActiveRecord::Migration
  def change
    add_column :institutes, :logo, :string
  end
end
