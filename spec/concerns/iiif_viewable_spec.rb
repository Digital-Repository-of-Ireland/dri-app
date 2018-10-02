describe DRI::IIIFViewable do

  FITS_DATA = <<-FITSXML
              <?xml version=\"1.0\"?>\n<fits xmlns=\"http://hul.harvard.edu/ois/xml/ns/fits/fits_output\"
              xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://hul.harvard.edu/ois/xml/ns/fits/fits_output
              http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd\" version=\"0.8.5\" timestamp=\"08/06/16 10:28\">\n
              <identification>\n    <identity format=\"JPEG File Interchange Format\" mimetype=\"image/jpeg\" toolname=\"FITS\"
              toolversion=\"0.8.5\">\n      <tool toolname=\"Jhove\" toolversion=\"1.5\"/>\n
              <tool toolname=\"file utility\" toolversion=\"5.04\"/>\n      <tool toolname=\"Exiftool\" toolversion=\"9.13\"/>\n
              <tool toolname=\"NLNZ Metadata Extractor\" toolversion=\"3.4GA\"/>\n
              <version toolname=\"Jhove\" toolversion=\"1.5\">1.01</version>\n    </identity>\n
              </identification>\n  <fileinfo>\n    <size toolname=\"Jhove\" toolversion=\"1.5\">1438519</size>\n
              <lastmodified toolname=\"Exiftool\" toolversion=\"9.13\" status=\"SINGLE_RESULT\">2016:06:08 10:27:40+01:00</lastmodified>\n
              <filepath toolname=\"OIS File Information\" toolversion=\"0.2\"
              status=\"SINGLE_RESULT\">data/zw/12/z5/28/zw12z528p/content0/sample_image.jpeg</filepath>\n
              <filename toolname=\"OIS File Information\" toolversion=\"0.2\" status=\"SINGLE_RESULT\">sample_image.jpeg</filename>\n
              <md5checksum toolname=\"OIS File Information\"
              toolversion=\"0.2\" status=\"SINGLE_RESULT\">5f4980909749139fa57b6836a02e6c97</md5checksum>\n
              <fslastmodified toolname=\"OIS File Information\" toolversion=\"0.2\" status=\"SINGLE_RESULT\">1465378060000</fslastmodified>\n
              </fileinfo>\n  <filestatus>\n    <well-formed toolname=\"Jhove\" toolversion=\"1.5\"
              status=\"SINGLE_RESULT\">true</well-formed>\n    <valid toolname=\"Jhove\" toolversion=\"1.5\"
              status=\"SINGLE_RESULT\">true</valid>\n  </filestatus>\n  <metadata>\n    <image>\n
              <byteOrder toolname=\"Jhove\" toolversion=\"1.5\" status=\"SINGLE_RESULT\">big endian</byteOrder>\n
              <compressionScheme toolname=\"Jhove\" toolversion=\"1.5\" status=\"SINGLE_RESULT\">JPEG (old-style)</compressionScheme>\n
              <imageWidth toolname=\"Jhove\" toolversion=\"1.5\">3426</imageWidth>\n
              <imageHeight toolname=\"Jhove\" toolversion=\"1.5\">2753</imageHeight>\n
              <colorSpace toolname=\"Jhove\" toolversion=\"1.5\" status=\"SINGLE_RESULT\">YCbCr</colorSpace>\n
              <iccProfileName toolname=\"Exiftool\" toolversion=\"9.13\" status=\"SINGLE_RESULT\">EPSON
              Standard RGB - Gamma 1.8</iccProfileName>\n
              <YCbCrSubSampling toolname=\"Exiftool\" toolversion=\"9.13\" status=\"SINGLE_RESULT\">2 2</YCbCrSubSampling>\n
              <samplingFrequencyUnit toolname=\"Jhove\" toolversion=\"1.5\">in.</samplingFrequencyUnit>\n
              <xSamplingFrequency toolname=\"Jhove\" toolversion=\"1.5\">400</xSamplingFrequency>\n
              <ySamplingFrequency toolname=\"Jhove\" toolversion=\"1.5\">400</ySamplingFrequency>\n
              <bitsPerSample toolname=\"Jhove\" toolversion=\"1.5\">8 8 8</bitsPerSample>\n
              <samplesPerPixel toolname=\"Jhove\" toolversion=\"1.5\" status=\"SINGLE_RESULT\">3</samplesPerPixel>\n
              <lightSource toolname=\"NLNZ Metadata Extractor\" toolversion=\"3.4GA\" status=\"SINGLE_RESULT\">unknown</lightSource>\n
              <iccProfileVersion toolname=\"Exiftool\" toolversion=\"9.13\" status=\"SINGLE_RESULT\">2.2.0</iccProfileVersion>\n    </image>\n
              </metadata>\n  <statistics fitsExecutionTime=\"10010\">\n    <tool toolname=\"OIS Audio Information\" toolversion=\"0.1\"
              status=\"did not run\"/>\n    <tool toolname=\"ADL Tool\" toolversion=\"0.1\" status=\"did not run\"/>\n
              <tool toolname=\"Jhove\" toolversion=\"1.5\" executionTime=\"4715\"/>\n    <tool toolname=\"file utility\"
              toolversion=\"5.04\" executionTime=\"4681\"/>\n    <tool toolname=\"Exiftool\" toolversion=\"9.13\" executionTime=\"5591\"/>\n
              <tool toolname=\"NLNZ Metadata Extractor\" toolversion=\"3.4GA\" executionTime=\"4685\"/>\n
              <tool toolname=\"OIS File Information\" toolversion=\"0.2\" executionTime=\"970\"/>\n
              <tool toolname=\"OIS XML Metadata\" toolversion=\"0.2\" status=\"did not run\"/>\n
              <tool toolname=\"ffident\" toolversion=\"0.2\" executionTime=\"4678\"/>\n
              <tool toolname=\"Tika\" toolversion=\"1.3\" executionTime=\"9899\"/>\n  </statistics>\n</fits>
          FITSXML

  let(:iiif_test) { Class.new do
    include DRI::IIIFViewable
    include Rails.application.routes.url_helpers

    def initialize(object)
      @document = object
    end
  end
  }

  before(:each) do
    @login_user = FactoryBot.create(:admin)

    @tmp_upload_dir = Dir.mktmpdir
    @tmp_assets_dir = Dir.mktmpdir

    Settings.dri.uploads = @tmp_upload_dir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)
    @collection[:creator] = [@login_user.email]
    @collection[:status] = 'published'
    @collection.save

    @sound = FactoryBot.create(:sound)
    @sound[:status] = 'published'
    @sound[:creator] = [@login_user.email]
    @sound.governing_collection = @collection
    @sound.save

    allow_any_instance_of(GenericFileContent).to receive(:external_content)
    allow_any_instance_of(GenericFileContent).to receive(:external_content)

    FileUtils.cp(File.join(fixture_path, 'sample_image.jpeg'),
      File.join(@tmp_upload_dir, 'sample_image.jpeg'))

    @generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
    @generic_file.batch = @sound
    @generic_file.apply_depositor_metadata(@login_user.email)
    file = LocalFile.new(fedora_id: @generic_file.id, ds_id: 'content')
    options = {}
    options[:mime_type] = 'image/jpeg'
    options[:file_name] = 'sample_image.jpeg'
    options[:batch_id] = @sound.id

    file.add_file File.new(File.join(@tmp_upload_dir, 'sample_image.jpeg')), options
    file.save

    @generic_file.characterization.ng_xml = Nokogiri::XML(FITS_DATA)
    @generic_file.filename = ['sample_image.jpeg']
    @generic_file.label = 'sample_image.jpeg'
    @generic_file.append_metadata
    @generic_file.save

  end

  after(:each) do
    @login_user.delete
    FileUtils.remove_dir(@tmp_upload_dir, :force => true)
    FileUtils.remove_dir(@tmp_assets_dir, :force => true)

    @collection.delete
  end

  describe 'manifest' do

    it "should create a valid manifest for an object" do
      expect{iiif_test.new(SolrDocument.new(@sound.to_solr)).iiif_manifest.to_json}.to_not raise_error
    end

    it "should create a valid manifest for a collection" do
      expect{iiif_test.new(SolrDocument.new(@collection.to_solr)).iiif_manifest.to_json}.to_not raise_error
    end

    it "should set within for collection objects" do
      manifest = iiif_test.new(SolrDocument.new(@sound.to_solr)).iiif_manifest

      expect(manifest.within['@id']).to end_with("#{@collection.id}.json")
    end

    it "should include subcollections in the collection manifest" do
      @subcollection = FactoryBot.create(:collection)
      @subcollection.governing_collection = @collection
      @subcollection[:creator] = [@login_user.email]
      @subcollection.status = 'published'
      @subcollection.save

      @collection.reload

      manifest = iiif_test.new(SolrDocument.new(@collection.to_solr)).iiif_manifest

      expect(manifest.collections.length).to be 1
      expect(manifest.collections.first['@id']).to end_with("collection/#{@subcollection.id}.json")
    end

    it 'should add images to objects' do
      manifest = iiif_test.new(SolrDocument.new(@sound.to_solr)).iiif_manifest

      expect(manifest.sequences.length).to be 1
      expect(manifest.sequences.first.canvases.length).to be 1
      expect(manifest.sequences.first.canvases.first.images.length).to be 1

      expect(manifest.sequences.first.canvases.first.images.first.resource['@id']).to end_with(
        "#{@sound.id}:#{@generic_file.id}/full/full/0/default.jpg")
    end

  end
end
