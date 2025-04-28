class DoiMetadata < ActiveRecord::Base
  belongs_to :datacite_doi

  serialize :title, coder: YAML
  serialize :subject, coder: YAML
  serialize :description, coder: YAML
  serialize :rights, coder: YAML
  serialize :creator, coder: YAML
  serialize :creation_date, coder: YAML
  serialize :published_date, coder: YAML
  serialize :resource_type, coder: YAML

  RESOURCE_TYPE_GENERAL = %w(AudioVisual
                             Award
                             Book
                             BookChapter
                             Collection
                             ComputationalNotebook
                             ConferencePaper
                             ConferenceProceeding
                             DataPaper
                             Dataset
                             Dissertation
                             Event
                             Image
                             InteractiveResource
                             Instrument
                             Journal
                             JournalArticle
                             Model
                             OutputManagmentPlan
                             PeerReview
                             PhysicalObject
                             Preprint
                             Project
                             Report
                             Service
                             Software
                             Sound
                             Standard
                             StudyRegistration
                             Text
                             Worklow
                             Other
                          )  

  def metadata_fields
    %w(title subject creator description creation_date published_date type)
  end

  def to_xml
    resource_type = resource_type_general

    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.resource('xmlns' => 'http://datacite.org/schema/kernel-4',
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xsi:schemaLocation'=>'http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd') {
        # mandatory entries
        xml.identifier self.datacite_doi.doi, identifierType: 'DOI'
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

        if resource_type_general.is_a?(Array)
          xml.resourceType(resource_type_general[1], resourceTypeGeneral: resource_type_general[0])
        else
          xml.resourceType '', resourceTypeGeneral: resource_type_general
        end
        
      }
    end

    builder.to_xml
  end

  def publication_year
    Time.now.year
  end

  def resource_type_general
    resource_type_matches = resource_type.map(&:camelcase).intersection(RESOURCE_TYPE_GENERAL)
    return resource_type_matches.first unless resource_type_matches.empty?
   
    downcased = resource_type.map(&:downcase)

    return ["Other", "3D"] if downcased.include?("3d")
    return "AudioVisual" if downcased.include?("movingimage") || downcased.include?("video")
    return "Sound" if downcased.include?("audio")
    return ["Other", resource_type[0]]
  end
end
