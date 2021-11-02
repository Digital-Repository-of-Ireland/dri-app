# frozen_string_literal: true
module Storage
  class Filesystem
    def initialize
      @dir = Settings.filesystem.directory
      FileUtils.mkdir_p(@dir) unless Dir.exist?(@dir)
    end

    def bucket_exists?(bucket)
      Dir.exist?(bucket_path(bucket))
    end

    # Create bucket
    def create_bucket(bucket)
      bucket_name = hash_dir(bucket)
      FileUtils.mkdir_p(bucket_name)
    end

    def delete_bucket(bucket)
      bucket_to_delete = bucket_path(bucket)
      FileUtils.remove_entry_secure(bucket_to_delete, true) unless bucket_to_delete.nil?
    end

    def delete_surrogates(bucket, key)
      FileUtils.rm_f Dir.glob(File.join(hash_dir(bucket), "#{key}_*"))
    end

    def get_surrogates(object, file, expire = nil)
      bucket = object.respond_to?(:id) ? object.id : object
      key = file.respond_to?(:id) ? file.id : file

      surrogate_file_names = list_files(bucket)

      @surrogates_hash = {}

      surrogate_file_names.each do |filename|
        if filename_match?(filename, key)
          url = surrogate_url(bucket, filename, expire)
          @surrogates_hash[key_from_filename(key, filename)] = url
        end
      end

      @surrogates_hash
    end

    def list_surrogates(bucket)
      list_files(bucket)
    end

    def surrogate_exists?(bucket, key)
      files = list_files(bucket)
      surrogate = files.find { |e| /#{key}/ =~ e }

      return nil if surrogate.blank?

      File.exist?(surrogate) ? true : nil
    end

    def surrogate_info(bucket, key)
      surrogates_hash = {}
      files = list_files(bucket)

      return surrogates_hash if files.blank?
      files.each do |file|
        next unless filename_match?(file, key)

        filename = Pathname.new(file).basename.to_s
        surrogates_hash[filename] = file_info(filename, File.stat(file))
      end

      surrogates_hash
    end

    def file_info(filename, stat)
      {
        content_type: MIME::Types.type_for(filename).first.content_type,
        content_length: stat.size,
        last_modified: stat.mtime,
        etag: ''
      }
    end

    def surrogate_url(bucket, key, _expire = nil)
      files = list_files(bucket)
      surrogate = files.find { |e| /#{key}/ =~ e }

      surrogate.present? && File.exist?(surrogate) ? surrogate : nil
    end

    def file_url(bucket, key)
      surrogate_url(bucket, key)
    end

    def store_surrogate(bucket, surrogate_file, surrogate_key, _mimetype = nil)
      file_path = File.join(hash_dir(bucket), surrogate_key)
      FileUtils.copy(surrogate_file, file_path)

      File.exist?(file_path)
    end

    def store_file(bucket, file, file_key, mimetype = nil)
      store_surrogate(bucket, file, file_key, mimetype)
    end

    private

    def bucket_path(bucket)
      hash_dir(bucket)
    end

    def key_from_filename(generic_file_id, filename)
      File.basename(filename, '.*').split("#{generic_file_id}_")[1]
    end

    def filename_match?(filename, generic_file_id)
      /#{generic_file_id}_([-a-zA-z0-9]*)\..*/ =~ filename
    end

    def hash_dir(bucket)
      return File.join(@dir, bucket) unless bucket.index('.').nil?

      sub_dir = ''
      index = 0

      4.times do
        sub_dir = File.join(sub_dir, bucket[index..index + 1])
        index += 2
        break if index > (bucket.length - 1)
      end

      File.join(@dir, sub_dir, bucket)
    end

    def list_files(bucket)
      Dir.glob("#{bucket_path(bucket)}/*").select { |f| File.file? f }
    end
  end
end
