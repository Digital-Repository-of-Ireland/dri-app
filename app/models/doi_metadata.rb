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
    ['title','subject','creator','description','creation_date','published_date']
  end

  def to_xml
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    xml.resource('xmlns'=>'http://datacite.org/schema/kernel-3',
                'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:schemaLocation'=>'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd') {
      xml.identifier self.datacite_doi.doi, :identifierType => 'DOI'
      xml.creators {
       self.creator.each do |c|
         xml.creator {
           xml.creatorName c
         }
       end
      }
      xml.titles {
        self.title.each do |t|
          xml.title t unless t.blank?
        end
      }
      xml.publisher DoiConfig.publisher
      xml.publicationYear publication_year
      xml.subjects {
        self.subject.each do |s|
          xml.subject s unless s.blank?
        end
      }
      xml.descriptions {
        self.description.each do |d|
          xml.description d, :descriptionType => 'Abstract' unless d.blank?
        end
      }
      if self.creation_date.present? || self.published_date.present?
        xml.dates {
          xml.date(self.creation_date.first, :dateType => 'Created') unless self.creation_date.blank? || self.creation_date.first.blank?
          xml.date(self.published_date.first, :dateType => 'Issued') unless self.published_date.blank? || self.published_date.first.blank?
        }
      end
      if self.rights.present?
        xml.rightsList {
          self.rights.each do |r|
            xml.rights r
          end
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
