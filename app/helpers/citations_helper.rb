# frozen_string_literal: true
module CitationsHelper
  include DRI::CitationsBehaviours::NameBehaviour

  def export_as_apa_citation(object, doi = nil, depositing_institute = nil)
    cp = CiteProc::Processor.new style: 'apa', format: 'text'
    render_citation(cp, object, doi, depositing_institute)
  end

  def export_as_chicago_citation(object, doi = nil, depositing_institute = nil)
    cp = CiteProc::Processor.new style: 'chicago-note-bibliography', format: 'text'
    render_citation(cp, object, doi, depositing_institute)
  end

  def export_as_mla_citation(object, doi = nil, depositing_institute = nil)
    cp = CiteProc::Processor.new style: 'modern-language-association', format: 'text'
    render_citation(cp, object, doi, depositing_institute)
  end

  def to_citeproc(object, doi = nil, depositing_institute = nil)
    csl_hash = {
      type: "webpage",
      id: object.alternate_id,
      title: object.title.join('. '),
      author: get_authors(object.creator),
      'container-title' => 'Digital Repository of Ireland'
    }
    csl_hash[:DOI] = doi if doi
    csl_hash[:issued] = object.published_at if object.published_at.present?
    csl_hash[:publisher] = depositing_institute if depositing_institute

    JSON.dump(csl_hash)
  end

  def render_citation(citeproc_processor, object, doi = nil, depositing_institute = nil)
    citeproc_processor.import([to_citeproc(object, doi, depositing_institute)])
    citeproc_processor.render(:bibliography, id: object.alternate_id).first
  end
end
