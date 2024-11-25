# frozen_string_literal: true
module CitationsHelper
  include DRI::CitationsBehaviours::NameBehaviour

  STYLE_AND_FORMAT = {
    apa: { style: 'apa', format: 'text' },
    chicago: { style: 'chicago-note-bibliography', format: 'text' },
    mla: { style: 'modern-language-association', format: 'text' }
  }.freeze
  module PriorityTypes
    # The TYPES array represents the hierarchy of types in line with Europeana practices.
    TYPES = ['Collection', '3D', 'Software', 'InteractiveResource', 'MovingImage', 'Sound', 'Dataset', 'Text', 'Image'].freeze
  end
  ACCESS_DATE_STRING = "(Accessed: #{Time.current.strftime('%Y/%m/%d')})".freeze

  def export_as_apa_citation(object, doi = nil, depositing_institute = nil)
    render_citation(STYLE_AND_FORMAT[:apa], object, doi, depositing_institute)
  end

  def export_as_chicago_citation(object, doi = nil, depositing_institute = nil)
    render_citation(STYLE_AND_FORMAT[:chicago], object, doi, depositing_institute)
  end

  def export_as_mla_citation(object, doi = nil, depositing_institute = nil)
    render_citation(STYLE_AND_FORMAT[:mla], object, doi, depositing_institute)
  end

  def export_as_dri_citation_general(object, doi = nil, depositing_institute = nil)
    citation_parts = []
    add_creator(citation_parts, object, depositing_institute, true)
    add_title(citation_parts, object)
    add_type(citation_parts, object, CitationsHelper::PriorityTypes::TYPES)
    add_depositor(citation_parts)
    add_system_gen_date(citation_parts, object)
    add_depositor_res(citation_parts, depositing_institute)
    add_doi(citation_parts, doi)
    add_current_date(citation_parts)
    citation_parts.join(" ")
  end

  def export_as_dri_citation_research(object, doi = nil, depositing_institute = nil)
    citation_parts = []
    add_depositor_res(citation_parts, depositing_institute)
    add_title(citation_parts, object)
    add_creator(citation_parts, object, depositing_institute, true)
    add_creation_date(citation_parts, object)
    add_type(citation_parts, object, CitationsHelper::PriorityTypes::TYPES)
    add_depositor(citation_parts)
    add_system_gen_date(citation_parts, object)
    add_doi(citation_parts, doi)
    add_current_date(citation_parts)
    citation_parts.join(" ")
  end

  def to_citeproc(object, doi = nil, depositing_institute = nil)
    csl_hash = {
      type: "webpage",
      id: object.alternate_id,
      title: object.title.join('. '),
      author: get_authors(object.creator),
      'container-title' => "#{t('dri.views.citation.publisher_name')}",
    }
    csl_hash[:DOI] = doi if doi
    csl_hash[:issued] = object.published_at if object.published_at.present?
    csl_hash[:publisher] = depositing_institute if depositing_institute

    JSON.dump(csl_hash)
  end

  def render_citation(style_and_format, object, doi = nil, depositing_institute = nil)
    cp = CiteProc::Processor.new(style_and_format)
    render_csl(cp, object, doi, depositing_institute)
  end

  def render_csl(citeproc_processor, object, doi = nil, depositing_institute = nil)
    citeproc_processor.import([to_citeproc(object, doi, depositing_institute)])
    citeproc_processor.render(:bibliography, id: object.alternate_id).first
  end

  private

  def add_depositor(citation_parts)
    citation_parts << "#{t('dri.views.citation.publisher_name')}"
  end

  def add_depositor_res(citation_parts, depositing_institute)
    citation_parts << "#{depositing_institute} #{t('dri.views.citation.depositor')}." if depositing_institute.to_s.strip.present?
  end

  def add_title(citation_parts, object)
    italic_title = "<i>#{object.title.join('.')}.</i>"
    citation_parts << italic_title if object.title.to_s.strip.present?
  end

  def add_creator(citation_parts, object, depositing_institute, researsher)
    object.creator.each_with_index do |creator, index|
      if depositing_institute != creator || researsher
        if researsher
          citation_parts << "#{creator}#{index == object.creator.size - 1 ? '.' : ','}"
        else
          citation_parts << "#{creator}#{index == object.creator.size - 1 ? '' : ','}"
        end
      end
    end
  end

  def add_type(citation_parts, object, priotiry_types)
    types = object.type.map(&:downcase)
    type = priotiry_types.find { |x| types.include?(x.downcase.delete(' ')) }
    type ||= object.type.first if types.any?
    citation_parts << "#{type} #{t('dri.views.citation.type')}." if type.present?
  end

  def add_system_gen_date(citation_parts, object)
    if object.published_at.present?
      begin
        formatted_date = DateTime.parse(object.published_at).strftime('%Y')
        citation_parts << "(#{formatted_date})"
      rescue ArgumentError => e
        puts "Error parsing date: #{e.message}"
      end
    end
    citation_parts << "#{t('dri.views.citation.publisher')}."
  end

  def add_doi(citation_parts, doi)
    citation_parts << "#{t('dri.views.citation.doi_sub_link')}#{doi}" if doi.to_s.strip.present?
  end

  def add_current_date(citation_parts)
    citation_parts << ACCESS_DATE_STRING
  end

  def extract_dates(dates)
    dates.map do |element|
      if element.include?("name=")
        element.match(/name=(.*?);/)&.captures&.first
      elsif element.include?("start=")
        element.match(/start=(.*?);/)&.captures&.first
      elsif element.include?("end=")
        element.match(/end=(.*?);/)&.captures&.first
      else
        element
      end
    end.compact.join(',')
  end
  
  def add_creation_date(citation_parts, object)
    creation_date_string = nil
    
    creation_date_string = if object.respond_to?(:creation_date) && object.creation_date.is_a?(Array) && object.creation_date.any? && object.creation_date.join.strip.present?
                             extract_dates(object.creation_date)
                           elsif object.date.is_a?(Array) && object.date.any? && object.date.join.strip.present?
                             extract_dates(object.date)
                           end
    
    if creation_date_string && !creation_date_string.strip.empty?
      citation_parts << "(#{creation_date_string})."
    else
      citation_parts << "."
    end
  end
end
