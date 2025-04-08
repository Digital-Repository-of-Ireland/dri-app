require 'checksum'

module DRI::Duplicable
  extend ActiveSupport::Concern

  def checksum_metadata(object)
    if object.attached_files.key?(:descMetadata)
      xml = object.attached_files[:descMetadata].content
      object.metadata_checksum = Checksum.md5_string(xml)
    end
  end

  def warn_if_has_duplicates(object)
    duplicates = find_object_duplicates(object)
    return if duplicates.blank?

    warning = t(
      'dri.flash.notice.duplicate_object_ingested',
      duplicates: duplicates.map { |o| "'" + o["id"] + "'" }.join(", ").html_safe
    )
    flash[:alert] = warning
    @warnings = warning
  end

  def find_object_duplicates(object)
    if object.governing_collection.present?
      Solr::Query.new(
          duplicate_query(object)
        ).to_a.delete_if { |obj| obj.alternate_id == object.alternate_id }
    end
  end

  private

  def duplicate_query(object)
    checksum_field = 'metadata_checksum_ssi'
    governed_field = 'isGovernedBy_ssim'
    
    query = "#{checksum_field}:\"#{object.metadata_checksum}\""
    query += " AND #{governed_field}:\"#{object.governing_collection.alternate_id}\""

    query
  end

end
