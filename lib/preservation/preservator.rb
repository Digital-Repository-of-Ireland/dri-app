# frozen_string_literal: true
require 'moab'
require 'fileutils'

module Preservation
  # Orchestrates preservation of a digital object into its Moab AIP
  # (Archival Information Package): creating the on-disk directory
  # structure, writing its metadata attributes/datastreams, and
  # creating/updating its version-inventory and signature-catalog
  # manifests.
  #
  # This class is kept as a thin orchestrator: signature-catalog lookups,
  # attributes/datastream writing, manifest building, and integrity
  # verification each live in their own collaborator class.
  class Preservator
    include Preservation::PreservationHelpers

    attr_accessor :base_dir, :object, :version

    def initialize(object, version = nil)
      self.object = object
      self.version = version || object.object_version
    end

    # create_moab_dir
    # Creates MOAB preservation directory structure and saves metadata there
    #
    def create_moab_dirs
      target_path = manifest_path(object.alternate_id, version)
      if File.directory?(target_path)
        err_string = "The Moab directory #{target_path} for "\
          "#{object.alternate_id} version #{version} already exists"
        Rails.logger.error(err_string)
        raise DRI::Exceptions::InternalError, err_string
      end

      make_dir(
        [
          version_path(object.alternate_id, version),
          metadata_path(object.alternate_id, version),
          content_path(object.alternate_id, version)
        ]
      )
    end

    def remove_moab_dirs(force = false)
      # check if status was ever published and if so do not delete unless force is set true
      attribute_files = Dir.glob("#{aip_dir(object.alternate_id)}/**/attributes.json")

      if attribute_files.blank?
        Rails.logger.error "No attribute files found, MOAB dirs not removed #{object.alternate_id}"
        return
      end

      published = false
      attribute_files.each do |attr|
        File.foreach(attr) do |file|
          data = JSON.load file
          published = true if data['status'] == 'published'
        end
      end

      if published && !force
        Rails.logger.error "Not removing MOAB dirs for previously published object #{object.alternate_id}"
        return
      end
      FileUtils.remove_dir(aip_dir(object.alternate_id), force: true)
    end

    def existing_filepath(file_path)
      catalog_lookup.existing_filepath(file_path)
    end

    def signature_catalog
      catalog_lookup.current
    end

    def signature_catalog_from_path(manifest_path)
      catalog_lookup.from_path(manifest_path)
    end

    # preserve
    def preserve(datastreams = nil)
      create_moab_dirs

      saved = attributes_writer.write_attributes
      return false unless saved

      dslist = [attributes_writer.attributes_path]

      if datastreams.present?
        datastreams.each do |ds|
          saved = attributes_writer.write_datastream(ds, object.attached_files[ds])
          return false unless saved

          dslist << attributes_writer.datastream_path(ds)
        end
      end

      manifest_manager.create_or_update(dslist)
    end

    # preserve_assets
    def preserve_assets(changes)
      create_moab_dirs
      attributes_writer.write_attributes
      changes[:modified] ||= {}
      changes[:modified]['metadata'] = [attributes_writer.attributes_path]

      manifest_manager.update(changes)
    end

    def create_or_update_manifests(datastream_list)
      manifest_manager.create_or_update(datastream_list)
    end

    # create_manifests
    def create_manifests
      manifest_manager.create
    end

    # update_manifests
    # changes: hash with keys :added, :modified and :deleted. Each is an array of filenames
    def update_manifests(changes)
      manifest_manager.update(changes)
    end

    def verify
      IntegrityVerifier.new(object).call
    end

    def file_inventory_from_path(version_id, manifest_path)
      manifest_manager.file_inventory_from_path(version_id, manifest_path)
    end

    private

    def catalog_lookup
      @catalog_lookup ||= SignatureCatalogLookup.new(object, version)
    end

    def attributes_writer
      @attributes_writer ||= AttributesWriter.new(object, version)
    end

    def manifest_manager
      @manifest_manager ||= ManifestManager.new(object, version)
    end
  end
end
