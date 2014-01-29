require "hydra/derivatives/shell_based_processor"
require "hydra/derivatives/processor"
require "hydra/derivatives/image"
require 'open3'
require 'storage/s3_interface'


Hydra::Derivatives::ShellBasedProcessor.module_eval do

  # Force the Hydra Derivatives processors to save surrogates to CEPH instead of FEDORA datastream
  def encode_datastream(dest_dsid, file_suffix, mime_type, options = '') #, pid)
        out_file = nil
        output_file = Dir::Tmpname.create(['sufia', ".#{file_suffix}"], Hydra::Derivatives.temp_file_base){}
        source_datastream.to_tempfile do |f|
          self.class.encode(f.path, options, output_file)
        end
        out_file = File.open(output_file, "rb")

        bucket_id = object.batch.nil? ? object.pid : object.batch.pid
        filename = "#{bucket_id}_#{dest_dsid}.#{file_suffix}"

        Storage::S3Interface.store_surrogate(bucket_id, out_file, filename)
        File.unlink(output_file)
  end

end

Hydra::Derivatives::Image.module_eval do

  def create_resized_image(output_datastream, size, format, quality=nil)
    create_image(output_datastream, format, quality) do |xfrm|
      xfrm.resize(size) if size.present?
    end
  end

  def write_image(output_datastream, xfrm)
    out_file = nil
    output_file = Dir::Tmpname.create('sufia', Hydra::Derivatives.temp_file_base){}
    xfrm.write(output_file)

    format = xfrm["format"].downcase
    bucket_id = object.batch.nil? ? object.pid : object.batch.pid
    filename = "#{bucket_id}_#{output_datastream.dsid}.#{format}"

    out_file = File.open(output_file, "rb")
    Storage::S3Interface.store_surrogate(bucket_id, out_file, filename)
    File.unlink(output_file)
  end

  def load_image_transformer
     source_datastream.to_tempfile do |f|
       MiniMagick::Image.read(f.read)
     end
  end

end
