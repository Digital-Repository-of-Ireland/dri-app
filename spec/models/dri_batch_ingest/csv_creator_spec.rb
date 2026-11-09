require 'rails_helper'
require 'csv'

describe DRIBatchIngest::CsvCreator do

  it 'should create a csv from files' do
    base_dir = File.join(file_fixture_path, 'ingest')

    creator = described_class.new(
      base_dir,
      'user@example.com',
      'test1'
    )

    creator.create('metadata', 'data', 'preservation')
    manifest = CSV.read(creator.csv_file)
    expect(manifest.length).to eq 5
    expect(manifest[1].length).to eq 11
    expect(manifest[-3][3..-1]).to contain_exactly(
      "metadata/object1.xml",
      "metadata",
      "data/object1.jpeg",
      "asset",
      "preservation/object1.jpeg",
      "preservation"
      )
    expect(manifest[-2][3..-1]).to contain_exactly(
      "metadata/object2.xml",
      "metadata",
      "data/object2.jpeg",
      "asset",
      "preservation/object2.jpeg",
      "preservation"
      )
    expect(manifest[-1][3..-1]).to contain_exactly(
      "metadata/object3.xml",
      "metadata",
      "data/object3/afile.jpeg",
      "asset",
      "data/object3/bfile.jpeg",
      "asset"
      )
    File.unlink(creator.csv_file)
  end
end
