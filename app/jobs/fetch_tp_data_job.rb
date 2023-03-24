class FetchTpDataJob
  require 'faraday'
  require 'faraday_middleware'
  require 'json'

  @queue = :fetch_tp_data

  def self.perform(object_id, story_id)
    object = DRI::Identifier.retrieve_object(object_id)
    story_endpoint = Settings.transcribathon.story_endpoint
    item_endpoint = Settings.transcribathon.item_endpoint

    print("Fetching Transcribaton data for object #{object_id} #{story_id}\n")
    Rails.logger.info "Fetching Transcribathon data for object #{object_id} #{story_id}"

    conn = Faraday.new(url: "#{story_endpoint}#{story_id}") do |faraday|
      faraday.adapter :httpclient
      faraday.response :json
    end

    response = conn.get()
    json_input = response.body

    # Get list of item ids
    item_ids = json_input[0]['Items'].map{ |i| i['ItemId'] }
    #conn.close()

    # Get the Transcribathon Story (should already exist)
    story = TpStory.where(story_id: story_id)

    
    # Get Items from TP-API
    item_ids.each do |item_id|

      conn = Faraday.new(url: "#{item_endpoint}#{item_id}") do |faraday|
        faraday.adapter :httpclient
        faraday.response :json
      end

      response = conn.get()
      json_input = response.body

      # Parse the JSON response and create the item      
      item = TpItem.where(item_id: item_id).first_or_initialize()
      item.story_id = story_id
      item.start_date = json_input['DateStart']
      item.end_date = json_input['DateEnd']
      item.save

      # Parse the JSON response and create the items, people and places
      json_input['Places'].map {
        |p|
        place = TpPlace.where(place_id: p['PlaceId']).first_or_initialize()
        place.item_id = item_id
        place.place_name = p['Name']
        place.latitude = p['Latitude']
        place.longitude = p['Longitude']
        place.wikidata_id = p['WikidataId']
        place.wikidata_name = p['WikidataName']
        place.save
      }
        
      json_input['Persons'].map {
        |q|
        person = TpPerson.where(person_id: q['PersonId']).first_or_initialize()
        person.item_id = item_id
        person.first_name = q['FirstName']
        person.last_name = q['LastName']
        person.birth_place = q['BirthPlace']
        person.birth_date = q['BirthDate']
        person.death_place = q['DeathPlace']
        person.death_date = q['DeathDate']
        person.person_description = q['Description']
        person.save
      }
    end

  end

end
