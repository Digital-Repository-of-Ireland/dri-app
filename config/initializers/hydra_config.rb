# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

Blacklight::AccessControls.configure do |config|
  # This specifies the solr field names of permissions-related fields.
  # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
  # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
  #
  config.permissions.read.group           = "read_access_group_ssim"
  config.permissions.read.individual      = "read_access_person_ssim"
  config.permissions.edit.group           = "edit_access_group_ssim"
  config.permissions.edit.individual      = "edit_access_person_ssim"
  config.permissions.manager.group          = "manager_access_group_ssim"
  config.permissions.manager.individual     = "manager_access_person_ssim"

  # specify the user model
  config.user_model = 'User'
end
