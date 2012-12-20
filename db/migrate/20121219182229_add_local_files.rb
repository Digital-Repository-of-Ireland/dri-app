class AddLocalFiles < ActiveRecord::Migration
  def up
    create_table :local_files do |t|
        t.string  :path
        t.string  :fedora_id
        t.string  :ds_id
        t.string  :mime_type
        t.integer :version
    end
  end

  def down
    drop_table :local_files
  end
end
