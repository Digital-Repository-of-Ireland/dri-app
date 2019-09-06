class AddLogoToInstitutes < ActiveRecord::Migration[4.2]
  def change
    add_column :institutes, :logo, :string
  end
end
