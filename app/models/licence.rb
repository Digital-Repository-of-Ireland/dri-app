class Licence < ActiveRecord::Base
  scope :supported, -> { where.not(name: ['Orphan Work','Educational Use','All Rights Reserved']) }

  validates_uniqueness_of :name

  # representation of licence used in json api
  #
  # @return [Hash] json 
  def show
    as_json(only: [:name, :description, :url])
  end
end
