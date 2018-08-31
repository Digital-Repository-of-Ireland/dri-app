require 'checksum'

module DRI::Duplicable
  extend ActiveSupport::Concern

  def checksum_metadata(object)
    if object.attached_files.key?(:descMetadata)
      xml = object.attached_files[:descMetadata].content
      object.metadata_md5 = Checksum.md5_string(xml)
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
      ActiveFedora::SolrService.query(
        duplicate_query(object),
        defType: 'edismax',
        rows: '10',
        fl: 'id'
      ).delete_if { |obj| obj['id'] == object.id }
    end
  end

  private

  def duplicate_query(object)
    md5_field = ActiveFedora.index_field_mapper.solr_name(
      'metadata_md5',
      :stored_searchable,
      type: :string
    )
    governed_field = ActiveFedora.index_field_mapper.solr_name(
      'isGovernedBy',
      :stored_searchable,
      type: :symbol
    )
    query = "#{md5_field}:\"#{object.metadata_md5}\""
    query += " AND #{governed_field}:\"#{object.governing_collection.id}\""

    query
  end

end
