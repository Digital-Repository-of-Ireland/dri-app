module ApplicationHelper
  require 'storage/s3_interface'

  # Extract file datastream info from fedora object
  def get_datastreams doc
    @datastreams = ActiveFedora::Base.find(doc.id, {:cast => true}).datastreams
    ""
  end

  def get_surrogates doc
    @surrogates = Storage::S3Interface.get_surrogates doc
  end
  
  def get_collections
    collections = DRI::Model::Collection.find(:depositor => current_user.to_s)
    collections.collect{ |c| [c.title, c.pid] }
  end

  def get_governing_collection( object )
    if !object.governing_collection.nil?
      object.governing_collection.pid
    end
  end

  def existing_collection_for( object_id )
    get_current_collection.items.to_a.find {|b| b.id == object_id}
  end

  def get_partial_name( object )
    object.class.to_s.downcase.gsub("-"," ").parameterize("_")
  end

  def is_collection?( document )
    document["type_ssm"].first.casecmp("collection") == 0 ? true : false
  end

end
