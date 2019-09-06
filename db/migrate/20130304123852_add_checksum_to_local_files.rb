class AddChecksumToLocalFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :local_files, :checksum, :string
  end
end
