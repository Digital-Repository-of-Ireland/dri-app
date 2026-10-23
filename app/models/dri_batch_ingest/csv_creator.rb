# frozen_string_literal: true
require "csv"
require "tmpdir"

class DRIBatchIngest::CsvCreator
  attr_reader :csv_file

  def initialize(base_dir, user_email, collection)
    @user_email = user_email
    @base_dir = base_dir

    ingest_name = "#{collection}-#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}"

    temp_dir = Dir.mktmpdir
    @csv_file = File.join(temp_dir, "#{ingest_name}.csv")
    @header = [ingest_name, @user_email]
  end

  def create(metadata_path, asset_path = nil, preservation_path = nil)
    Dir.chdir(@base_dir) do
      metadata, assets, preservation = files_to_import(metadata_path, asset_path, preservation_path)
      to_csv(metadata, assets, preservation)
    end
  end

  def files_to_import(metadata_path, asset_path = nil, preservation_path = nil)
    metadata = {}
    assets = {}
    preservation = {}

    # Get the metadata
    Dir.glob(File.join(metadata_path, '*.xml')).each do |mfile|
      basename = File.basename(mfile, '.xml').to_sym
      metadata[basename] = mfile

      # Does it have any corresponding data files?
      asset_files(assets, asset_path, basename) unless asset_path.nil?

      # Does it have any corresponding preservation-only data files?
      preservation_files(preservation, preservation_path, basename) unless preservation_path.nil?
    end

    [metadata, assets, preservation]
  end

  def to_csv(metadata, assets, preservation)
    CSV.open(@csv_file, "w") do |csv|
      csv << @header
      csv << title_row(max_row_length(assets) + max_row_length(preservation))

      metadata.each do |key, m|
        row = [key, @user_email, Time.now, m, 'metadata']

        asset_list = assets.key?(key) ? assets[key] : []
        preservation_list = preservation.key?(key) ? preservation[key] : []

        asset_list.each { |a| row.concat([a, 'asset']) }
        preservation_list.each { |p| row.concat([p, 'preservation']) }

        csv << row
      end
    end
  end

  def asset_files(assets, asset_path, basename)
    tmp = find_files(asset_path, basename)
    assets[basename] = tmp if tmp.count.positive?
  end

  def preservation_files(preservation, preservation_path, basename)
    tmp = find_files(preservation_path, basename)
    preservation[basename] = tmp if tmp.count.positive?
  end

  def find_files(path_for_files, basename)
    Dir.glob(["#{path_for_files}/#{basename}/*.*", "#{path_for_files}/#{basename}.*", "#{path_for_files}/#{basename}_[0-9]*.*", "#{path_for_files}/#{basename}-[0-9]*.*"])
  end

  def title_row(max_row_length)
    title_row = ['Title', 'Creator', 'Date Issued']
    (0..max_row_length).each do |_i|
      title_row.concat(['File', 'Label'])
    end
    title_row
  end

  def max_row_length(files_hash)
    return 0 if files_hash.blank?

    files_hash.values.max_by(&:length).length
  end
end
