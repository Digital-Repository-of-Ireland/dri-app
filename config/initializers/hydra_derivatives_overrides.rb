require "hydra/derivatives/shell_based_processor"
require "hydra/derivatives/processor"
require "hydra/derivatives/image"
require 'open3'
require 'storage/s3_interface'


Hydra::Derivatives::ShellBasedProcessor.module_eval do

  # Force the Hydra Derivatives processors to save surrogates to CEPH instead of FEDORA datastream
  def encode_file(dest_dsid, file_suffix, mime_type, options = '') #, pid)
    out_file = nil
    output_file = Dir::Tmpname.create(['sufia', ".#{file_suffix}"], Hydra::Derivatives.temp_file_base){}
    source_file.to_tempfile do |f|
      self.class.encode(f.path, options, output_file)
    end
    out_file = File.open(output_file, "rb")

    bucket_id = object.batch.nil? ? object.id : object.batch.id
    filename = "#{object.id}_#{dest_dsid}.#{file_suffix}"

    storage = Storage::S3Interface.new
    storage.store_surrogate(bucket_id, out_file, filename)
    File.unlink(output_file)
  end

end

