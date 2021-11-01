# frozen_string_literal: true
module DRI::Readable
  extend ActiveSupport::Concern

  # If the restricted read is inherited find the correct reader group to use
  def governing_reader_group(collection_id)
    doc = SolrDocument.find(collection_id)
    read_groups = doc[Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)]
    return UserGroup::Group.find_by(name: collection_id) if read_groups&.include?(collection_id)

    # Else check to see if ancestors have the read group set
    inherited_read_group(doc)
  end

  # Attempt to find a read group set on an ancestor collection
  def inherited_read_group(doc)
    return nil if doc['ancestor_id_ssim'].blank?
    ancestor_docs = doc.ancestor_docs
    read_group = nil

    doc['ancestor_id_ssim'].reverse_each do |ancestor_id|
      ancestordoc = ancestor_docs[ancestor_id]
      read_groups = ancestordoc[Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)]
      if read_groups&.include?(ancestor_id)
        read_group = UserGroup::Group.find_by(name: ancestor_id)
        break
      end
    end

    read_group
  end
end
