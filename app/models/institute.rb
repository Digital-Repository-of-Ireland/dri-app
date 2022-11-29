class Institute < ActiveRecord::Base
  require 'storage/s3_interface'
  require 'validators'

  has_one :brand, dependent: :destroy
  has_many :organisation_users, dependent: :destroy
  has_many :users, -> { distinct }, through: :organisation_users, class_name: 'UserGroup::User'

  validates_uniqueness_of :name

  def manager
    org_manager&.email
  end

  def manager=(user_or_email)
    user = if user_or_email.is_a?(UserGroup::User)
             user_or_email
           else
             UserGroup::User.find_by(email: user_or_email)
           end
    return if user.nil?

    raise ArgumentError, "User must be an organisation manager." unless user.is_om?

    replace_manager(user)
  end

  def org_manager
    OrganisationUser.find_by(institute: self, manager:true)&.user
  end

  def add_logo(upload)
    return unless validate_logo(upload)

    store_logo(upload)
    save
  end

  # Return all collections for this institute
  def collections
    return [] if name.nil?

    query = Solr::Query.new(
      collections_query,
      100,
      fq: "-ancestor_id_ssim:[* TO *]"
    )
    query.to_a
  end

  def local_storage_dir
    Rails.root.join(Settings.dri.logos)
  end

  def validate_logo(logo)
    return false if logo.blank? || Validators.media_type(logo) != 'image'

    begin
      Validators.virus_scan(logo)

      valid = true
    rescue DRI::Exceptions::VirusDetected => e
      logger.error "Virus detected in institute logo: #{e.message}"
      valid = false
    end

    valid
  end

  def store_logo(upload)
    b = brand || Brand.new
    b.filename = upload.original_filename
    b.content_type = upload.content_type
    b.file_contents = upload.read
    b.save

    self.brand = b
  end

  private

  def collections_query
    "#{Solr::SchemaFields.searchable_string('institute')}:\"" + name.mb_chars.downcase +
      "\" AND " + "#{Solr::SchemaFields.searchable_string('type')}:Collection"
  end

  def replace_manager(user)
    current_manager = OrganisationUser.find_by(institute: self, manager: true)
    return if current_manager&.user == user

    ou = OrganisationUser.find_or_create_by(institute: self, user: user)
    ou.manager = true
    ou.save

    if current_manager
      current_manager.manager = false
      current_manager.save
    end
  end
end
