module DRI::Readable
  extend ActiveSupport::Concern

  # If the restricted read is inherited find the correct reader group to use
  def governing_reader_group(collection_id)
    result = ActiveFedora::SolrService.query("id:#{collection_id}")
    doc = SolrDocument.new(result.pop)
    read_groups = doc[Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)]

    if read_groups && read_groups.include?(collection_id)
      return UserGroup::Group.find_by(name: collection_id)
    end

    # Else check to see if ancestors have the read group set
    inherited_read_group(doc)
  end

  # Attempt to find a read group set on an ancestor collection
  def inherited_read_group(doc)
    read_group = nil

    return read_group unless doc[Solrizer.solr_name('ancestor_id', :stored_searchable, type: :text)].present?

    doc[Solrizer.solr_name('ancestor_id', :stored_searchable, type: :text)].reverse_each do |ancestor|
      result = ActiveFedora::SolrService.query("id:#{ancestor}")
      ancestordoc = SolrDocument.new(result.pop) if result.size > 0
      read_groups = ancestordoc[Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)]
      if read_groups.present? && read_groups.include?(ancestor)
        read_group = UserGroup::Group.find_by(name: ancestor)
        break
      end
    end

    read_group
  end
end
