class AddIiifMainToAggregation < ActiveRecord::Migration[5.2]
  def change
    add_column :aggregations, :iiif_main, :boolean
  end
end
