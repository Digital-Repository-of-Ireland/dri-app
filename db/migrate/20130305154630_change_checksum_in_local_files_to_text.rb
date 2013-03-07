class ChangeChecksumInLocalFilesToText < ActiveRecord::Migration
  def change
    change_column :local_files, :checksum, :text, :limit => nil
  end
end
