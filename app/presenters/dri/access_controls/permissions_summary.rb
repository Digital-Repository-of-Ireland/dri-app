# frozen_string_literal: true

module DRI
  module AccessControls
    # Summarizes a document's effective read/asset-file access settings
    # into the small hash of labels/flags used by both the access-controls
    # tree (HTML) and the CSV report.
    class PermissionsSummary
      def self.for(document)
        new(document).call
      end

      def initialize(document)
        @document = document
      end

      def call
        permissions = {}
        read_groups = document.ancestor_field('read_access_group_ssim')

        case read_groups
        when ['registered']
          permissions[:read_access] = 'logged-in'
          permissions[:read_label] = I18n.t('dri.views.objects.access_controls.report.logged_in')
        when ['public']
          permissions[:read_access] = 'public'
          permissions[:read_label] = I18n.t('dri.views.objects.access_controls.report.public')
        else
          permissions[:read_access] = 'restricted'
          permissions[:read_label] = I18n.t('dri.views.objects.access_controls.report.restricted')
        end

        read_master = document.read_master? ? 'public' : 'private'
        permissions[:assets] = read_master
        permissions[:assets_label] = I18n.t("dri.views.objects.access_controls.inherit_strings.#{read_master}")

        permissions
      end

      private

      attr_reader :document
    end
  end
end
