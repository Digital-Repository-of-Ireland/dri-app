class JobMailer < ActionMailer::Base
  default from: Devise.mailer_sender

  def archive_ready_mail(file, user, object)
    Rails.logger.debug("[Job MAILER] sending mail to #{user}")
    if !user.nil? && !user.empty?
      @user = user
      @file = file
      @object = object
      @title = object.title.first
      mail(to: @user, subject: "Your download is ready")
    end
  end

end
