require "sufia/generic_file/characterization"

Sufia::GenericFile::Characterization.module_eval do

 # Extract the metadata from the content datastream and record it in the characterization datastream
 def characterize
   metadata = content.extract_metadata
   characterization.ng_xml = metadata if metadata.present?
   append_metadata
   self.filename = [self.label]
   save
 end

end
