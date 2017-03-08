class UserBackgroundTask < ActiveRecord::Base
  belongs_to :user, class_name: 'UserGroup::User'

  paginates_per 10

  scope :available, ->{ where("name <> 'nil'") }

  def update
    return if %w(completed failed killed).include?(self.status)

    status = Resque::Plugins::Status::Hash.get(self.job)
    return if status.nil?

    self.status = status.status unless self.status == status.status
    self.message = status.message unless self.message == status.message
    self.name = status.name if self.name.nil?

    save
  end
end
