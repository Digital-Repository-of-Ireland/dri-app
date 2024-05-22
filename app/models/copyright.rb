class Copyright < ActiveRecord::Base
  scope :supported, -> { where(supported: true) }

  validates_uniqueness_of :name

  # representation of copyright used in json api
  #
  # @return [Hash] json 
  def show
    as_json(only: [:name, :description, :url])
  end

  def label
    url.presence || name
  end
end

