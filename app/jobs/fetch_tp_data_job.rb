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

    story = TpStory.new(story_id: json_input[0]['StoryId'], dri_id: json_input[0]['ExternalRecordId'])
    story.save

    x = json_input[0]['Items'].count

    json_input[0]['Items'].map{
      |single_item|

      item = TpItem.new(story_id: json_input[0]['StoryId'],item_id: single_item['ItemId'],start_date: single_item['DateStart'],end_date: single_item['DateEnd'],item_link: single_item['ImageLink'][single_item['ImageLink'].index("https://"),single_item['ImageLink'].index("@type")-11])
      item.save

      place = TpPlace.new(item_id: single_item['ItemId'],place_id: single_item['Places'][0]['PlaceId'],place_name: single_item['Places'][0]['Name'],latitude: single_item['Places'][0]['Latitude'],longitude: single_item['Places'][0]['Longitude'],wikidata_id: single_item['Places'][0]['WikidataId'],wikidata_name: single_item['Places'][0]['WikidataName'])
      place.save

      #
      # person = TpPerson.new(
      #   item_id: ,
      #   person_id: ,
      #   first_name: ,
      #   last_name: ,
      #   birth_place: ,
      #   birth_date: ,
      #   death_place: ,
      #   death_date: ,
      #   person_description:
      # )
    }


      # for each item id get the item! endpoint is https://europeana.fresenia-dev.man.poznan.pl/dev/tp-api/items/[item_id]
      # "#{item_endpoint}#{item_id}"
      # create the tp_item entry with start and end dates
      # parse out people and places and populate tp_people and tp_places tables

  end

end
