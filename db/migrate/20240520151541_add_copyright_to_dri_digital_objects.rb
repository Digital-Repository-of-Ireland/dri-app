class AddCopyrightToDriDigitalObjects < ActiveRecord::Migration[6.1]
  def change
    add_column :dri_digital_objects, :copyright, :string
  end
end
