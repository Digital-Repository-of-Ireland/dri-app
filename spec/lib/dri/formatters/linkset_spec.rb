require 'rails_helper'

describe LinksetsController, type: :controller do
  let(:id) { '1' }

  describe '#mapped_links' do
    let(:target_types) { ['unknown_type', 'text', '3d'] }
    let(:target_3d) { ['unknown_type','3d', 'text'] }
    let(:target_unknown) { ['unknown_type'] }
    let(:target_empty) { [] }
    let(:map) do
      {
        'text' => 'https://schema.org/text_link',
        '3d'   => 'https://schema.org/3DModel'
      }
    end
    let(:formatter) { DRI::Formatters::Linkset.new(controller, {})}

    it 'returns the first link that is present in the map' do
      result = formatter.mapped_links(target_types, map)
      expect(result).to eq('https://schema.org/text_link')
    end

    it 'returns the last link that is present in the map' do
      result = formatter.mapped_links(target_3d, map)
      expect(result).to eq('https://schema.org/3DModel')
    end

    it 'returns nil if no link present in the map' do
      result = formatter.mapped_links(target_unknown, map)
      expect(result).to be_nil
    end

    it 'returns nil if target_types is empty' do
      result = formatter.mapped_links(target_empty, map)
      expect(result).to be_nil
    end
  end

  describe '#get_contributors' do 
    let(:identifiers) {[
      'name=Test, Test; authority=ORCID; identifier=https://orcid.org/0000-0000-0000-0000', 
      'name=Test1, Test1; authority=ORCID; identifier=https://orcid.org/0000-0000-0000-0001'
      ]}
    let(:identifiers_no_match) {[
      'name=Test, Test; authority=ORCID; identifier=https://org/0000-0000-0000-0000', 
      'name=Test1, Test1; authority=ORCID; identifier=https://org/0000-0000-0000-0001'
      ]}
    let(:identifiers_empty){[]}
    it 'returns the author ORCID links if match pattern' do
      @document = {}
      @document['contributor_tesim'] = identifiers
      result = DRI::Formatters::Linkset.new(controller, @document).contributors
      expect(result).to eq(['https://orcid.org/0000-0000-0000-0000', 'https://orcid.org/0000-0000-0000-0001'])
    end

    it 'returns nil if doesnt match pattern' do
      @document = {}
      @document['contributor_tesim'] = identifiers_no_match
      result = DRI::Formatters::Linkset.new(controller, @document).contributors
      expect(result).to eq([])
    end

    it 'returns nil if identifiers empty' do
      @document = {}
      @document['contributor_tesim'] = identifiers_empty
      result = DRI::Formatters::Linkset.new(controller, @document).contributors
      expect(result).to be nil
    end
  end

  describe '#object_items:read_master:true' do
    
    before do
      # set behavior for necessary methods
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:pdf?).and_return(true, false)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:text?).and_return(true, false)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:threeD?).and_return(true, false)
  
      # Create a double for @document and set its behavior
      @document = instance_double('Test')
      # Create behavior based in the instance 
      allow(@document).to receive(:read_master?).and_return(true)
    end
    
    it 'returns one item array for a single asset PDF type' do
      assets = [double("asset", "id" => "1", "mime_type_tesim" => ["application/pdf"])]

      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(true)
      allow(assets[0]).to receive(:pdf?).and_return(true)
      allow(assets[0]).to receive(:threeD?).and_return(false)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("application/pdf")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:type]).to eq('application/pdf')
    end

    it 'returns two items array for a single asset TEXT type' do
      assets = [double("asset", "id" => "1", "mime_type_tesim" => ["text/plain"])]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(true)
      allow(assets[0]).to receive(:pdf?).and_return(true)
      allow(assets[0]).to receive(:threeD?).and_return(false)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("text/plain")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:type]).to eq('application/pdf')
      expect(result.last[:type]).to eq('text/plain')
    end

    it 'returns one item array for a single asset 3D type' do
      assets = [double("asset", "id" => "1", "mime_type_tesim" => ["glTF binary model"])]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(false)
      allow(assets[0]).to receive(:pdf?).and_return(false)
      allow(assets[0]).to receive(:threeD?).and_return(true)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("glTF binary model")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:type]).to eq('glTF binary model')
    end

    it 'returns 3 items array for other types' do
      assets = [
        double("asset", "id" => "1", "mime_type_tesim" => ["audio/mp3"]),
        double("asset", "id" => "2", "mime_type_tesim" => ["application/mp4"]),
        double("asset", "id" => "3", "mime_type_tesim" => ["image/png"])
      ]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(false)
      allow(assets[0]).to receive(:pdf?).and_return(false)
      allow(assets[0]).to receive(:threeD?).and_return(false)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("audio/mp3")

      allow(assets[1]).to receive(:fetch).with("id", nil).and_return("2")
      allow(assets[1]).to receive(:text?).and_return(false)
      allow(assets[1]).to receive(:pdf?).and_return(false)
      allow(assets[1]).to receive(:threeD?).and_return(false)
      allow(assets[1]).to receive(:fetch).with(any_args).and_return("application/mp4")

      allow(assets[2]).to receive(:fetch).with("id", nil).and_return("3")
      allow(assets[2]).to receive(:text?).and_return(false)
      allow(assets[2]).to receive(:pdf?).and_return(false)
      allow(assets[2]).to receive(:threeD?).and_return(false)
      allow(assets[2]).to receive(:fetch).with(any_args).and_return("image/png")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result[0][:type]).to eq('audio/mp3')
      expect(result[1][:type]).to eq('application/mp4')
      expect(result[2][:type]).to eq('image/png')
    end

  end

  describe '#object_items:read_master:false' do
    
    before do
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:pdf?).and_return(true, false)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:text?).and_return(true, false)
      allow_any_instance_of(DRI::Asset::MimeTypes).to receive(:threeD?).and_return(true, false)
  
      @document = instance_double('Test')
      allow(@document).to receive(:read_master?).and_return(false)
    end

    it 'returns one item array for a single asset PDF type' do
      assets = [double("asset", "id" => "1", "mime_type_tesim" => ["application/pdf"])]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(true)
      allow(assets[0]).to receive(:pdf?).and_return(true)
      allow(assets[0]).to receive(:threeD?).and_return(false)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("application/pdf")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:type]).to eq('application/pdf')
    end

    it 'returns one item array for a single asset TEXT type' do
      assets = [double("asset", "id" => "1", "mime_type_tesim" => ["text/plain"])]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(true)
      allow(assets[0]).to receive(:pdf?).and_return(true)
      allow(assets[0]).to receive(:threeD?).and_return(false)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("text/plain")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:type]).to eq('application/pdf')
    end

    it 'returns one item array for a single asset 3D type' do
      assets = [double("asset", "id" => "1", "mime_type_tesim" => ["glTF binary model"])]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(false)
      allow(assets[0]).to receive(:pdf?).and_return(false)
      allow(assets[0]).to receive(:threeD?).and_return(true)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("glTF binary model")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:type]).to eq('glTF binary model')
    end

    it 'returns 3 items array for other types' do
      assets = [
        double("asset", "id" => "1", "mime_type_tesim" => ["audio/mp3"]),
        double("asset", "id" => "2", "mime_type_tesim" => ["application/mp4"]),
        double("asset", "id" => "3", "mime_type_tesim" => ["image/png"])
      ]
      allow(assets[0]).to receive(:fetch).with("id", nil).and_return("1")
      allow(assets[0]).to receive(:text?).and_return(false)
      allow(assets[0]).to receive(:pdf?).and_return(false)
      allow(assets[0]).to receive(:threeD?).and_return(false)
      allow(assets[0]).to receive(:fetch).with(any_args).and_return("audio/mp3")

      allow(assets[1]).to receive(:fetch).with("id", nil).and_return("2")
      allow(assets[1]).to receive(:text?).and_return(false)
      allow(assets[1]).to receive(:pdf?).and_return(false)
      allow(assets[1]).to receive(:threeD?).and_return(false)
      allow(assets[1]).to receive(:fetch).with(any_args).and_return("application/mp4")

      allow(assets[2]).to receive(:fetch).with("id", nil).and_return("3")
      allow(assets[2]).to receive(:text?).and_return(false)
      allow(assets[2]).to receive(:pdf?).and_return(false)
      allow(assets[2]).to receive(:threeD?).and_return(false)
      allow(assets[2]).to receive(:fetch).with(any_args).and_return("image/png")
      
      result = DRI::Formatters::Linkset.new(controller, @document).object_items(assets, id)
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result[0][:type]).to eq('audio/mp3')
      expect(result[1][:type]).to eq('application/mp4')
      expect(result[2][:type]).to eq('image/png')
    end

  end

  describe '#metadata_link' do

    before do
      @document = OpenStruct.new({ id: '1', 'has_model_ssim' => ['DRI::QualifiedDublinCore'] })
      allow_any_instance_of(DRI::Formatters::Linkset).to receive(:mapped_links).and_return(nil)
    end


    it 'returns the correct metadata link without profile' do
      result = DRI::Formatters::Linkset.new(controller, @document).metadata_link

      expect(result[:href]).to eq("http://test.host/objects/#{id}/metadata")
      expect(result[:type]).to eq('application/xml')
      expect(result[:profile]).to be_nil
    end

    it 'returns the correct metadata link with profile' do
      allow_any_instance_of(DRI::Formatters::Linkset).to receive(:mapped_links).and_return('http://test.com/profile')
      
      result = DRI::Formatters::Linkset.new(controller, @document).metadata_link

      expect(result[:href]).to eq("http://test.host/objects/#{id}/metadata")
      expect(result[:type]).to eq('application/xml')
      expect(result[:profile]).to eq('http://test.com/profile')
    end
  end

  describe '#document_licence_link' do

    before do
      allow_any_instance_of(DRI::Formatters::Linkset).to receive(:mapped_links).and_return(nil)
    end

    it 'returns nil for no licence object' do
      @document = SolrDocument.new({ id: '1', 'has_model_ssim' => ['DRI::QualifiedDublinCore'], 'licence_tesim' => ['No Licence'] })
      result = DRI::Formatters::Linkset.new(controller, @document).document_licence_link

      expect(result).to be_nil
    end

    it 'returns the licence url' do
      licence = Licence.new(
        name: 'test', description: 'this is a test', url: 'http://exaample.com'
      )
      licence.save
      @document = SolrDocument.new({ id: '1', 'has_model_ssim' => ['DRI::QualifiedDublinCore'], 'licence_tesim' => ['test'] })
      result = DRI::Formatters::Linkset.new(controller, @document).document_licence_link

      expect(result).to eq('http://exaample.com')
      licence.destroy if licence
    end
  end

  describe '#reverse_link_builder' do
    let(:ancestor_id) { ['ancestor_id'] }
    let(:object_id) { 'object_id' }

    it 'returns an array of reverse links' do
      link_assets = [
        { 'href1' => 'link1' },
        { 'href2' => 'link2' }
      ]

      result = DRI::Formatters::Linkset.new(controller, {}).reverse_link_builder(link_assets, ancestor_id, object_id)

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)

      expect(result[0][:anchor]).to eq('link1')
      expect(result[0][:collection]).to be_an(Array)
      expect(result[0][:collection].size).to eq(1)
      expect(result[0][:collection][0][:href]).to eq("http://test.host/catalog/#{ancestor_id.first}")
      expect(result[0][:collection][0][:type]).to eq('text/html')

      expect(result[1][:anchor]).to eq('link2')
      expect(result[1][:collection]).to be_an(Array)
      expect(result[1][:collection].size).to eq(1)
      expect(result[1][:collection][0][:href]).to eq("http://test.host/catalog/#{ancestor_id.first}")
      expect(result[1][:collection][0][:type]).to eq('text/html')
    end
  end

  describe DRI::Formatters::Linkset, type: :model do
    let(:controller) { double('LinksetsController') }
    let(:linkset) { described_class.new(controller, document) }
  
    describe '#collection_objects' do
      let(:document) { double('SolrDocument') }
      let(:collection_id) { 'parent_id' }
  
      before do
        allow(controller).to receive(:catalog_url).and_return('http://localhost:3000/catalog/obj1')
      end
  
      context 'when an object is linked to the main collection' do
        it 'includes the object link with MIME type' do
          mock_object = OpenStruct.new(id: 'obj1', isGovernedBy_ssim: [collection_id], mime_type: 'application/pdf')
          objects = [mock_object]
  
          allow(document).to receive(:children).with(chunk: 1000, subcollections_only: false).and_return(objects)
  
          result = linkset.collection_objects
  
          expect(result).to include(href: 'http://localhost:3000/catalog/obj1', type: 'application/pdf')
        end
      end
  
      context 'when an object is linked to a subcollection' do
        it 'includes the subcollection link' do
          mock_object1 = OpenStruct.new(id: 'obj1', isGovernedBy_ssim: [collection_id], mime_type: 'text/html', collection?: true)
          mock_object2 = OpenStruct.new(id: 'obj2', isGovernedBy_ssim: ['other_parent_id'], mime_type: 'text/html', collection?: true)

          objects = [mock_object1, mock_object2]
  
          allow(document).to receive(:children).with(chunk: 1000, subcollections_only: false).and_return(objects)
  
          result = linkset.collection_objects
  
          expect(result).to include(href: 'http://localhost:3000/catalog/obj1', type: 'text/html')
        end
      end
  
      context 'when no objects are found' do
        it 'returns an empty array' do
          allow(document).to receive(:children).with(chunk: 1000, subcollections_only: false).and_return([])
  
          result = linkset.collection_objects
  
          expect(result).to eq([])
        end
      end
    end
  end
end