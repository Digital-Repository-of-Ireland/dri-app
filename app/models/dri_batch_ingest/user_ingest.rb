# frozen_string_literal: true
class DRIBatchIngest::UserIngest < ActiveRecord::Base
  belongs_to :user, class_name: 'UserGroup::User'

  has_many :batches, class_name: 'DRIBatchIngest::IngestBatch'
end
