describe XmlDatastream do
  describe 'load_xml' do
    
    it 'raises an exception if no schema' do
      file = fixture_file_upload("/invalid_metadata_noschema.xml", "text/xml")
      class << file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect { XmlDatastream.new.load_xml(file) }.to raise_error(DRI::Exceptions::ValidationErrors)
    end

    it 'returns an exception if schema invalid' do
      file = fixture_file_upload("/invalid_metadata_schemaparse.xml", "text/xml")
      class << file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect { XmlDatastream.new.load_xml(file) }.to raise_error(DRI::Exceptions::ValidationErrors)
    end

    it 'returns an exception if metadata invalid' do
      file = fixture_file_upload("/invalid_xml_metadata.xml", "text/xml")
      class << file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect { XmlDatastream.new.load_xml(file) }.to raise_error(DRI::Exceptions::InvalidXML)
    end

    it 'sets the metadata standard' do
      file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      xml_ds = XmlDatastream.new
      xml_ds.load_xml(file)
      expect(xml_ds.metadata_standard).to eq(:qdc)
    end

    it 'sets the metadata class' do
      file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      xml_ds = XmlDatastream.new
      xml_ds.load_xml(file)
      expect(xml_ds.metadata_class).to eq("DRI::Metadata::QualifiedDublinCore")
    end

  end
end
