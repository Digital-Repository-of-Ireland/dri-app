module Storage
  class Filesystem

  def initialize
    @dir = Settings.filesystem.directory
    FileUtils.mkdir_p(@dir) unless Dir.exists?(@dir)
  end

  def bucket_exists?(bucket)
    Dir.exists?(bucket_path(bucket))
  end
      
  # Create bucket
  def create_bucket(bucket)
    bucket_name = hash_dir(bucket)
    FileUtils.mkdir_p(bucket_name)
  end
  
  def delete_bucket(bucket)
    bucket_to_delete = bucket_path(bucket)
    FileUtils.remove_entry_secure(bucket_to_delete) unless bucket_to_delete.nil?
  end

  def delete_surrogates(bucket, key)
    FileUtils.rm_f Dir.glob(File.join(hash_dir(bucket), "#{key}_*"))
  end
  
  def get_surrogates(object, file, expire=nil)
    bucket = object.respond_to?(:id) ? object.id : object
    key = file.respond_to?(:id) ? file.id : file

    surrogate_file_names = list_files(bucket)

    @surrogates_hash = {}
    
    surrogate_file_names.each do |filename|
      begin
        if match = filename_match?(filename, key)
          url = surrogate_url(bucket, filename, expire)
          @surrogates_hash[match] = url
        end
      rescue Exception => e
        Rails.logger.debug "Problem getting url for file #{file} : #{e.to_s}"
      end
    end
    
    @surrogates_hash
  end

  def surrogate_exists?(bucket, key)
    files = list_files(bucket)
    surrogate = files.find { |e| /#{key}/ =~ e }
    
    return nil unless surrogate.present?
    
    File.exists?(surrogate) ? true : nil
  end

  def surrogate_info(bucket, key)
    surrogates_hash = {}
    begin
      files = list_files(bucket)

      if files.present?
        files.each do |file|
          if filename_match?(file, key)
            stat = File.stat(file)
            filename = Pathname.new(file).basename.to_s
            surrogates_hash[filename] = {}
            surrogates_hash[filename][:content_type] = MIME::Types.type_for(filename).first.content_type
            surrogates_hash[filename][:content_length] = stat.size
            surrogates_hash[filename][:last_modified] = stat.mtime
            surrogates_hash[filename][:etag] = ''
          end
        end
      else
        Rails.logger.debug "Problem getting surrogate info for file #{key}"
      end
    rescue Exception => e
      Rails.logger.debug "Problem getting surrogate info for file #{key} : #{e}"
    end

    surrogates_hash
  end

  def surrogate_url(bucket, key, expire=nil)
    files = list_files(bucket)
    surrogate = files.find { |e| /#{key}/ =~ e }
    
    return nil unless surrogate.present?
    
    File.exists?(surrogate) ? surrogate : nil
  end

  def store_surrogate(bucket, surrogate_file, surrogate_key)
    file_path = File.join(hash_dir(bucket), surrogate_key)
    FileUtils.copy(surrogate_file, file_path)
    
    File.exists?(file_path)
  end
    
  private

  def bucket_path(bucket)
    hashed_bucket = hash_dir(bucket)
    
    return hashed_bucket if Dir.exists?(hashed_bucket)
  end

  def filename_match?(filename, key)
    filename.match(/#{key}_([-a-zA-z0-9]*)\..*/)

    $1
  end

  def hash_dir(bucket)
    sub_dir = ''
    index = 0

    4.times {
      sub_dir = File.join(sub_dir, bucket[index..index+1])
      index += 2
      break if index > (bucket.length - 1)
    }

    File.join(@dir, sub_dir, bucket)
  end
  
  def list_files(bucket)
    Dir.glob("#{bucket_path(bucket)}/*").select{ |f| File.file? f }
  end

  end
end