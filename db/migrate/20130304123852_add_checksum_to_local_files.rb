class AddChecksumToLocalFiles < ActiveRecord::Migration
  def change
    add_column :local_files, :checksum, :string
  end
end
