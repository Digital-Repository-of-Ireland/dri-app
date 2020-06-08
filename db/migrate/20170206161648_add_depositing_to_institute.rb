class AddDepositingToInstitute < ActiveRecord::Migration[4.2]
  def change
    add_column :institutes, :depositing, :boolean
  end
end
