class AddDepositingToInstitute < ActiveRecord::Migration
  def change
    add_column :institutes, :depositing, :boolean
  end
end
