# frozen_string_literal: true
module CitationsHelper
  include DRI::CitationsBehaviours::NameBehaviour

  STYLE_AND_FORMAT = {
    apa: { style: 'apa', format: 'text' },
    chicago: { style: 'chicago-note-bibliography', format: 'text' },
    mla: { style: 'modern-language-association', format: 'text' }
  }.freeze
  DRI_STRING = 'Digital Repository of Ireland'.freeze
  DEPOSITOR_STRING = '[Depositor]'.freeze
  PUBLISHER_STRING = '[Publisher]'.freeze
  TYPE_STRING = '[Type]'.freeze
  ACCESS_DATE_STRING = "(Accessed: #{Time.current.strftime('%Y/%m/%d')})".freeze
  COLLECTION_STRING = 'Collection'.freeze
  DOI_PRE_LINK = 'https://doi.org/'.freeze

  def export_as_apa_citation(object, doi = nil, depositing_institute = nil)
    render_citation(STYLE_AND_FORMAT[:apa], object, doi, depositing_institute)
  end

  def export_as_chicago_citation(object, doi = nil, depositing_institute = nil)
    render_citation(STYLE_AND_FORMAT[:chicago], object, doi, depositing_institute)
  end

  def export_as_mla_citation(object, doi = nil, depositing_institute = nil)
    render_citation(STYLE_AND_FORMAT[:mla], object, doi, depositing_institute)
  end

  # TODO: Update Tests
  def export_as_dri_citation_dri_general(object, doi = nil, depositing_institute = nil)
    citation_parts = []
    add_depositor(citation_parts)
    add_published_date(citation_parts, object)
    add_title(citation_parts, object)
    add_creator(citation_parts, object, depositing_institute, false)
    add_temporal_coverage(citation_parts, object)
    add_type(citation_parts, object, ObjectsController::PrimaryTypes::TYPES)
    add_publiser(citation_parts, object)
    add_system_gen_date(citation_parts, object)
    add_doi(citation_parts, doi)
    add_current_date(citation_parts)
    citation_parts.join(" ")
  end

  def export_as_dri_citation_dri_research(object, doi = nil, depositing_institute = nil)
    citation_parts = []
    add_creator(citation_parts, object, depositing_institute, false)
    add_creation_date(citation_parts, object)
    add_title(citation_parts, object)
    add_type(citation_parts, object, ObjectsController::PrimaryTypes::TYPES)
    add_publiser(citation_parts, object)
    add_system_gen_date(citation_parts, object)
    add_depositor_res(citation_parts, depositing_institute)
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
      'container-title' => 'Digital Repository of Ireland',
      # Including the string "test" in a custom field
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
    citation_parts << DRI_STRING
  end

  def add_depositor_res(citation_parts, depositing_institute)
    citation_parts << "#{depositing_institute} #{DEPOSITOR_STRING}" if depositing_institute.to_s.strip.present?
  end

  def add_published_date(citation_parts, object)
    date = object.published_date.reject(&:empty?).first || object.date.reject(&:empty?).first || object.creation_date.reject(&:empty?).first
    citation_parts << (date.present? ? "(#{date})#{DEPOSITOR_STRING}" : DEPOSITOR_STRING)
  end

  def add_title(citation_parts, object)
    citation_parts << "#{object.title.join('. ')}." if object.title.to_s.strip.present?
  end

  def add_creator(citation_parts, object, depositing_institute, researsher)
    object.creator.each_with_index do |creator, index|
      if depositing_institute != creator || researsher
        citation_parts << "#{creator}#{index == object.creator.size - 1 ? '.' : ','}"
      end
    end
  end

  def add_temporal_coverage(citation_parts, object)
    citation_parts << "(#{object.temporal_coverage.first})" if object.temporal_coverage.first.present?
  end

  def add_type(citation_parts, object, primeTypes)
    type = object.type.find { |x| primeTypes.include?(x.downcase.delete(' ')) || x == COLLECTION_STRING }
    type ||= object.type.first
    citation_parts << "#{type} #{TYPE_STRING}" if type.to_s.strip.present?
  end

  def add_publiser(citation_parts, object)
    citation_parts << (object.publisher.present? ? "#{object.publisher}" : DRI_STRING)
  end

  def add_system_gen_date(citation_parts, object)
    if object.published_at.present?
      begin
        formatted_date = DateTime.parse(object.published_at).strftime('%Y')
        citation_parts << "(#{formatted_date}) #{PUBLISHER_STRING}"
      rescue ArgumentError => e
        puts "Error parsing date: #{e.message}"
      end
    elsif object.published_date.first.present?
      citation_parts << "(#{object.published_date.first}) #{PUBLISHER_STRING}"
    else
      citation_parts << PUBLISHER_STRING
    end
  end

  def add_doi(citation_parts, doi)
    citation_parts << "#{DOI_PRE_LINK}#{doi}" if doi.to_s.strip.present?
  end

  def add_current_date(citation_parts)
    citation_parts << ACCESS_DATE_STRING
  end

  def add_creation_date(citation_parts, object)
    citation_parts << "(#{object.date.first})" if object.date.first.to_s.strip.present?
  end
end
