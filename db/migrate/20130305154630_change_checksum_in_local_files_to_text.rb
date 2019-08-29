class ChangeChecksumInLocalFilesToText < ActiveRecord::Migration[4.2]
  def change
    change_column :local_files, :checksum, :text, :limit => nil
  end
end
