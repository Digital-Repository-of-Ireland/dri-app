module FlashTranslator


  def flash_for(message)

    case message

      when /ingestion/
        I18n.t('dri.flash.notice.digital_object_ingested', :locale => @user.locale)

      when /invalid metadata/
        strip_vars( I18n.t('dri.flash.alert.invalid_xml', :locale => @user.locale) )

      when /invalid schema/
        strip_vars( I18n.t('dri.flash.error.validation_errors', :locale => @user.locale) )

      when /invalid object/
        strip_vars( I18n.t('dri.flash.alert.invalid_object', :locale => @user.locale) )

      when /updating metadata/
        I18n.t('dri.flash.notice.metadata_updated', :locale => @user.locale)

      when /file upload/
        I18n.t('dri.flash.notice.file_uploaded', :locale => @user.locale)

      when /invalid file type/
        I18n.t('dri.flash.alert.invalid_file_type', :locale => @user.locale)

      when /virus detected/
        I18n.t('dri.flash.alert.virus_detected', :virus => 'Eicar-Test-Signature', :locale => @user.locale)

      when /invalid email or password/
        # User is not yet logged in and has no @user, will default to locale 'en'
        I18n.t('devise.failure.invalid', :locale => "en")

      when /new account/
        # User is not yet logged in and has no @user, will default to locale 'en'
        #I18n.t('user_groups.users.signup', :locale => "en")
        I18n.t('devise.failure.unconfirmed', :locale => "en")

      when /duplicate email/
        strip_vars( I18n.t('activerecord.errors.models.user_group/user.attributes.email.taken', :locale => "en") )

      when /password mismatch/
        strip_vars( I18n.t('activerecord.errors.models.user_group/user.attributes.password.confirmation', :locale => "en") )

      when /too short password/
        strip_vars( I18n.t('activerecord.errors.models.user_group/user.attributes.password.too_short', :locale => "en") )

      when /creating a collection/
        I18n.t('dri.flash.notice.collection_created', :locale => @user.locale)

      when /deleting a collection/
        I18n.t('dri.flash.notice.collection_deleted', :locale => @user.locale)

      when /removing an object from a collection/
        I18n.t('dri.flash.notice.removed_from_collection', :locale => @user.locale)

      when /cookie notification/
        I18n.t('dri.application.cookies.header', :locale => "en")

      when /cookie terms/
        I18n.t('dri.application.terms.header', :locale => "en")

      when /invalid profile image/
        strip_vars( I18n.t("user_groups.users.errors.validation_image_link", :locale => "en") )

      when /invalid collection/
        I18n.t('dri.flash.error.not_created', :locale => @user.locale)

      when /invalid update collection/
        strip_vars( I18n.t('dri.flash.error.not_updated', :locale => @user.locale) )

      when /application pending/
        I18n.t('user_groups.memberships.pending', :locale => @user.locale)

      when /membership approved/
        I18n.t('user_groups.memberships.approve', :locale => @user.locale)

      else "Unknown"

    end
  end

  # Method to remove %{foo} type variables from the flash messages.
  # It will return the longest continuous string in the message that does not
  # contain any variables.
  # It need only be called when we know that the message contains variables.
  #
  def strip_vars(message)
    bits = message.split(/%\{\w*\}/).sort_by(&:length).reverse
    bits.each do |bit|
      return bit unless bit.blank?
    end
    return message
  end

end
World(FlashTranslator)
