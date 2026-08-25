# frozen_string_literal: true

require "rails_helper"

RSpec.describe DRI::Exporters::ZipFile do
  let(:input_dir) { Dir.mktmpdir }
  let(:output_file) { Tempfile.new(["export", ".zip"]) }

  after do
    FileUtils.remove_dir(input_dir, force: true)
    output_file.close
    output_file.unlink
  end

  describe "#write" do
    it "zips a flat file into the archive" do
      File.write(File.join(input_dir, "hello.txt"), "hello world")

      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        expect(zip.glob("hello.txt").first.get_input_stream.read).to eq("hello world")
      end
    end

    it "recursively includes subdirectories" do
      FileUtils.mkdir_p(File.join(input_dir, "sub"))
      File.write(File.join(input_dir, "sub", "nested.txt"), "nested content")

      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        expect(zip.glob("sub/nested.txt").first.get_input_stream.read).to eq("nested content")
      end
    end

    it "recursively includes multiple levels of nested subdirectories" do
      FileUtils.mkdir_p(File.join(input_dir, "a", "b"))
      File.write(File.join(input_dir, "a", "b", "deep.txt"), "deep content")

      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        expect(zip.glob("a/b/deep.txt").first.get_input_stream.read).to eq("deep content")
      end
    end

    it "includes the input directory's contents but not the directory itself as an entry" do
      File.write(File.join(input_dir, "file.txt"), "x")

      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        names = zip.entries.map(&:name)
        expect(names).to include("file.txt")
        expect(names).not_to include(File.basename(input_dir))
      end
    end

    it "follows symlinks, archiving the linked file's actual content" do
      real_file = File.join(input_dir, "real.txt")
      File.write(real_file, "real content")
      File.symlink(real_file, File.join(input_dir, "link.txt"))

      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        expect(zip.glob("link.txt").first.get_input_stream.read).to eq("real content")
      end
    end

    it "produces an archive with no entries for an empty directory" do
      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        expect(zip.entries).to be_empty
      end
    end

    it "includes an empty subdirectory as its own entry" do
      FileUtils.mkdir_p(File.join(input_dir, "empty_sub"))

      described_class.new(input_dir, output_file.path).write

      Zip::File.open(output_file.path) do |zip|
        expect(zip.entries.map(&:name)).to include("empty_sub/")
      end
    end
  end
end