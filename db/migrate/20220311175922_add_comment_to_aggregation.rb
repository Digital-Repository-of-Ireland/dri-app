class AddCommentToAggregation < ActiveRecord::Migration[5.2]
  def change
    add_column :aggregations, :comment, :string
  end
end
