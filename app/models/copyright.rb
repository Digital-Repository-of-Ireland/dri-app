class Copyright < ActiveRecord::Base
  validates_uniqueness_of :name

  # representation of copyright used in json api
  #
  # @return [Hash] json 
  def show
    as_json(only: [:name, :description, :url])
  end
end
