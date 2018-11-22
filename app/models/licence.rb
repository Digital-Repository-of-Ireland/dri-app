class Licence < ActiveRecord::Base
  validates_uniqueness_of :name

  def show
    as_json(only: [:name, :description, :url])
  end
end
