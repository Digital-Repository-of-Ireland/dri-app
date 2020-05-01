require 'active_fedora/associations/collection_association.rb'

ActiveFedora::Associations::CollectionAssociation.class_eval do
  def destroy(*records)
    records = find(records) if records.any? { |record| record.is_a?(Integer) || record.is_a?(String) }
    delete_or_destroy(records, :destroy)
  end
end
