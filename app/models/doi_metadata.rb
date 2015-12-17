class DoiMetadata < ActiveRecord::Base
  belongs_to :datacite_doi

  serialize :title
  serialize :subject
  serialize :description
  serialize :rights
  serialize :creator
  serialize :creation_date
  serialize :published_date

  def metadata_fields
    %w(title subject creator description creation_date published_date)
  end

  def to_xml
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.resource('xmlns'=>'http://datacite.org/schema/kernel-3',
                'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:schemaLocation'=>'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd') {

        # mandatory entries
        xml.identifier self.datacite_doi.doi, :identifierType => 'DOI'
        xml.creators {
          creator.each do |c|
            xml.creator {
              xml.creatorName c
            }
          end
        }
        xml.titles {
          title.each { |t| xml.title t unless t.blank? }
        }
        xml.publisher DoiConfig.publisher
        xml.publicationYear publication_year
      }
    end

    builder.to_xml
  end

  def publication_year
    Time.now.year
  end

end
