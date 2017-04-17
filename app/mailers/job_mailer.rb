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

  def export_ready_mail(file, email, object_id)
    Rails.logger.debug("[Job MAILER] sending mail to #{email}")
    unless email.nil?
      @file = file
      @object_id = object_id
      mail(to: 'stuart.kenny@tchpc.tcd.ie', subject: "Your download is ready")
    end
  end

end
