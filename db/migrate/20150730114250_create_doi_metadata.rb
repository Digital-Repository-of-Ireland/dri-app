class CreateDoiMetadata < ActiveRecord::Migration
  def change
    create_table :doi_metadata do |t|
      t.references :datacite_doi, index: true
      t.text :title
      t.text :creator
      t.text :subject
      t.text :description
      t.text :rights
      t.text :creation_date
      t.text :published_date

      t.timestamps
    end
  end
end
