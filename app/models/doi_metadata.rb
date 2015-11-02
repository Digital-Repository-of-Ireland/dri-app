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

        unless subject.blank?
          xml.subjects {
            subject.each { |s| xml.subject s unless s.blank? }
          }
        end

        unless description.blank?
          xml.descriptions {
            description.each { |d| xml.description d, :descriptionType => 'Abstract' unless d.blank? }
          }
        end

        if creation_date.present? || published_date.present?
          xml.dates {
            xml.date(creation_date.first, :dateType => 'Created') unless creation_date.blank? || creation_date.first.blank?
            xml.date(published_date.first, :dateType => 'Issued') unless published_date.blank? || published_date.first.blank?
          }
        end
        if rights.present?
          xml.rightsList {
            rights.each { |r| xml.rights r }
          }
        end
      
      }
    end

    builder.to_xml
  end

  def publication_year
    Time.now.year
  end

end
