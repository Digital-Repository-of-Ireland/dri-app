class CreateAggregation < ActiveRecord::Migration[4.2]
  def change
    create_table :aggregations do |t|
      t.string :collection_id
      t.string :aggregation_id
      t.boolean :doi_from_metadata

      t.timestamps null: false
    end
  end
end
