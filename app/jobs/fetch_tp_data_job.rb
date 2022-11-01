class FetchTpDataJob
  require 'faraday'
  require 'faraday_middleware'
  require 'json'

  @queue = :fetch_tp_data

  def self.perform(object_id, story_id)
    object = DRI::Identifier.retrieve_object(object_id)
    story_endpoint = Settings.transcribathon.story_endpoint
    item_endpoint = Settings.transcribathon.item_endpoint

    # WIP: info here https://docs.google.com/document/d/15XiogCH-aFWGTmGeE5EjdWqlIeo_agu_0t2iEmT3nTk/edit
    # Get the story from tp_api
    # Create an entry in the tp_story table with our object id and the story id
    # for each item id returned by the stories api
    #  - get the item endpoint for that item id
    #  - create an entry in the tp_items table with story id, item id, start and end dates
    #  - for each person create an entry in the tp_persons table
    #  - for each place create an entry in the tp_places table

    print("Fetching Transcribaton data for object #{object_id} #{story_id}\n")
    Rails.logger.info "Fetching Transcribathon data for object #{object_id} #{story_id}"

    # get the story! endpoint is https://europeana.fresenia-dev.man.poznan.pl/dev/tp-api/stories/[story_id]
    # "#{story_endpoint}#{story_id}"
    # create a tp_story entry
    # parse out list of items

    conn = Faraday.new(url: "#{story_endpoint}#{story_id}") do |faraday|
      faraday.adapter :httpclient
      faraday.response :json
    end

    response = conn.get()
    json_input = response.body # to be parsed, just printing here to show we got it!

    dri_record_id = json_input[0]['ExternalRecordId']
    story_id = json_input[0]['StoryId']
    x = json_input[0]['Items'].count
    y = 0
    item_input = []

    # json_input[0]['Items'].each do |item|
    #   print("\n ITEM: #{y} --> \n")
    #   print("Item_id: #{item['ItemId']} \n")        #Working
    #   print("Date_start: #{item['DateStart']} \n")
    #   print("Date_end: #{item['DateEnd']} \n")
    #   print("Image_link: #{item['ImageLink']} \n")
    #   y+=1
    # end
    # item_id = item_input.map{|i| i["ItemId"]}
    # start_date = item_input.map{|i| i["DateStart"]}
    # end_date = item_input.map{|i| i["DateEnd"]}
    # item_link = item_input.map{|i| i["ImageLink"].gsub('\\', '')}

    # json_input[0]['Items'].map{|item| print("Item Id: #{item['ItemId']} \n")}


    #Mapping items and indexing as Arrays with [ItemId,DataStart,DataEnd,ImageLink]
    #Note: Image link is extracted from String
    mappedItems = json_input[0]['Items'].map{
      |item|
      [item['ItemId'],
      item['DateStart'],
      item['DateEnd'],
      item['ImageLink'][item['ImageLink'].index("https://"),item['ImageLink'].index("@type")-11]]
    }

    # mappedItems.each do |k|
    #   print("#{k} \n")
    # end

    # print("#{item_id}")





      # for each item id get the item! endpoint is https://europeana.fresenia-dev.man.poznan.pl/dev/tp-api/items/[item_id]
      # "#{item_endpoint}#{item_id}"
      # create the tp_item entry with start and end dates
      # parse out people and places and populate tp_people and tp_places tables

  end

end
