module RswagHelper

  ## 
  # handle case where add_param is first param, use ? instead of &
  #
  # @param  [String] url
  # @param  [Array]  param
  # @return [String] uri
  def add_param(url, param)
    uri = URI.parse(url)
    query_arr = URI.decode_www_form(uri.query || '') << param
    uri.query = URI.encode_www_form(query_arr)
    uri.to_s
  end

  # @param [String] status
  # @return [Institute] || nil
  def create_institute(status)
    if status == 'published'
      org = FactoryBot.create(:institute)
      org.save
      org
    end
  end

  # @param type [Symbol]
  # @param token [Boolean]
  # @return user [User]
  def create_user(type: :collection_manager, token: true)
    user = FactoryBot.create(type)
    user.create_token if token
    user.save
    user
  end

  # @param user [User]
  # @param type [Symbol]
  # @param title [String]
  # @param status [String]
  # @return collection [DRI::QualifiedDublinCore (Collection)]
  def create_collection_for(user, status: 'draft', title: 'test_collection')
    collection = FactoryBot.create(:collection)
    collection[:status] = status
    collection[:creator] = [user.to_s]
    collection[:title] = [title]
    collection[:date] = [DateTime.now.strftime("%Y-%m-%d")]
    collection.apply_depositor_metadata(user.to_s)
    collection.save
    collection
  end

  # @param user [User]
  # @param type [Symbol]
  # @param title [String]
  # @param status [String]
  # @return collection containing subcollection [DRI::QualifiedDublinCore (Collection)]
  def create_subcollection_for(user, status: 'draft')
    collection = create_collection_for(user, status: status)
    subcollection = create_collection_for(user, status: status, title: 'subcollection')
    subcollection.governing_collection = collection

    [collection, subcollection].each do |c|
      c.governed_items << create_object_for(user, status: status)
      c.save
    end

    collection
  end

  # @param user [User]
  # @param type [Symbol]
  # @param title [String]
  # @param status [String]
  # @return collection [DRI::QualifiedDublinCore (Object)]
  def create_object_for(user, type: :sound, status: 'draft', title: 'test_object')
    object = FactoryBot.create(type)
    object[:status] = status
    object[:title] = [title]
    object.apply_depositor_metadata(user.to_s)
    object.save
    object
  end

  # @return [Array]
  def bind_search_param
    # let is lazily evaluated and local_variable_get is not,
    # so that approach won't work
    # [binding.local_variable_get(param_name)]
    # note loading byebug complicates this since it provides a method named q
    return [q_ws] if defined? q_ws
    return [q] if defined? q
    raise ArgumentError, 'neither q nor q_ws defined'
  end

end
