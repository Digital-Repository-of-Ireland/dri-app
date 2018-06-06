 module DRI::Solr::Document::Oai
 
  def sets
    ancestor_sets = DRI::OaiProvider::AncestorSet
    ancestor_sets.fields = [{label: 'collection', solr_field: 'ancestor_id_tesim'}]
    ancestor_sets.sets_for(self)
  end

  def to_oai_dri
    DRI::Formatters::OAI.instance.encode(nil, o)
  end

  alias_method :export_as_oai_dri_xml, :to_oai_dri

end