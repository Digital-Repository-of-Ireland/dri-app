class DataciteDoi < ActiveRecord::Base

  scope :current, -> { order("version DESC").first }

  def doi
    doi = "DRI.#{self.object_id}"
 
    doi = "#{doi}-#{self.version}" if self.version && self.version > 0

    File.join(DoiConfig.prefix.to_s, doi)
  end 

  def object
    @object ||= ActiveFedora::Base.find(self.object_id, cast: true)
  end

  def publication_year
    Time.now.year
  end

  def requires_update?( object )
    !(arrays_equal?(self.object.title, object.title) && update = arrays_equal?(self.object.creator, object.creator))
  end

  def to_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.resource('xmlns'=>'http://datacite.org/schema/kernel-3',
                   'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance',
                   'xsi:schemaLocation'=>'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd') {
        xml.identifier self.doi, :identifierType => 'DOI'
        xml.creators {
          object.creator.each do |c|
            xml.creator {
              xml.creatorName c
            }
          end
        }
        xml.titles {
          object.title.each do |t|
            xml.title t
          end
        }
        xml.publisher DoiConfig.publisher
        xml.publicationYear publication_year
        xml.subjects {
          object.subject.each do |s|
            xml.subject s
          end
        }
        xml.descriptions {
          object.description.each do |d|
            xml.description d, :descriptionType => 'Abstract'
          end
        }

        if (object.creation_date.present?) || (object.published_date.present?)
          xml.dates {
            xml.date(object.creation_date.first, :dateType => 'Created') unless object.creation_date.blank?
            xml.date(object.published_date.first, :dateType => 'Issued') unless object.published_date.blank?
          }
        end

        xml.rights object.rights.first unless object.rights.blank?

      }
      end

      return builder.to_xml
    end

    def arrays_equal?(array_a, array_b)
      array_a.size == array_b.size && ((array_a-array_b) + (array_b-array_a)).blank?
    end

end
