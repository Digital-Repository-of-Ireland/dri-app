# Wraps a DRI object's metadata files and exposes presentation helpers
# used by MetadataController#show.
#
# Usage:
#   presenter = MetadataPresenter.new(object)
#   presenter.title        # => "MODS Metadata"
#   presenter.xml_content  # => raw XML string (fullMetadata or descMetadata)
#   presenter.styled_html  # => HTML string from XSL transform
#
module DRI
  class MetadataPresenter
    TITLES = {
      'qualifieddc' => 'Dublin Core Metadata',
      'record'      => 'MARC Metadata',
      'mods'        => 'MODS Metadata',
      'ead'         => 'EAD Metadata',
      'c'           => 'EAD Metadata',
      'RDF'         => 'Dublin Core Metadata (in RDF/XML)'
    }.freeze

    def initialize(object)
      @object = object
    end

    def title
      TITLES[desc_xml.root.name]
    end

    def xml_content
      if full_metadata_has_content?
        @object.attached_files[:fullMetadata].content
      else
        @object.attached_files[:descMetadata].content
      end
    end

    def styled_html
      xslt_for(desc_xml).transform(desc_xml).to_html
    end

    private

    def desc_xml
      @desc_xml ||= Nokogiri::XML(@object.attached_files[:descMetadata].content)
    end

    def full_metadata_has_content?
      return false unless @object.attached_files.key?(:fullMetadata)

      ng = @object.attached_files[:fullMetadata]&.ng_xml
      ng.present? && ng.root.children.present?
    end

    def xslt_for(xml)
      xslt_data = File.read("app/assets/stylesheets/#{xml.root.name}.xsl")
      Nokogiri::XSLT(xslt_data)
    end
  end
end