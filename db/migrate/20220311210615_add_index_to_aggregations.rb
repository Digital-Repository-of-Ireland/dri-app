class AddIndexToAggregations < ActiveRecord::Migration[5.2]
  def change
    add_index :aggregations, :collection_id, unique: true
  end
end
