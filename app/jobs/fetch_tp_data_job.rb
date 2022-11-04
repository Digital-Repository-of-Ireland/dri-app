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
    json_input = response.body

    story = TpStory.new(story_id: json_input[0]['StoryId'], dri_id: json_input[0]['ExternalRecordId'])

    #check if StoryId in database before saving
    if !TpStory.exists?(json_input[0]['StoryId'])
      story.save
    end

    x = json_input[0]['Items'].count

    json_input[0]['Items'].map{
      |i|

      item = TpItem.new(
        story_id: json_input[0]['StoryId'],
        item_id: i['ItemId'],
        start_date: i['DateStart'],
        end_date: i['DateEnd'],
        item_link: i['ImageLink'][i['ImageLink'].index("https://"),i['ImageLink'].index("@type")-11]
      )

      if !TpItem.exists?(i['ItemId'])
        item.save
      end
    }

    json_input[0]['Items'].map {
      |e|
      if !e['Places'].empty?
        e['Places'].map {
          |p|
          place = TpPlace.new(
            item_id: p['ItemId'],
            place_id: p['PlaceId'],
            place_name: p['Name'],
            latitude: p['Latitude'],
            longitude: p['Longitude'],
            wikidata_id: p['WikidataId'],
            wikidata_name: p['WikidataName']
          )
          place.save
        }
      end
    }



      # for each item id get the item! endpoint is https://europeana.fresenia-dev.man.poznan.pl/dev/tp-api/items/[item_id]
      # "#{item_endpoint}#{item_id}"
      # create the tp_item entry with start and end dates
      # parse out people and places and populate tp_people and tp_places tables

  end

end
