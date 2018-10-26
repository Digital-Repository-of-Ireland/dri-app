require "rails_helper"

describe DRI::Sorters do

  it "should sort filenames by trailing digits with decimal points" do
    labels = %w(DCLA.RDFA.006.08 DCLA.RDFA.006.20 DCLA.RDFA.006.07 DCLA.RDFA.006.13)
    ordered_labels = %w(DCLA.RDFA.006.07 DCLA.RDFA.006.08 DCLA.RDFA.006.13 DCLA.RDFA.006.20)

    expect(labels.sort { |a,b| DRI::Sorters.trailing_digits_sort(a,b) }).to eq ordered_labels
  end

  it "should sort filenames by trailing digits" do
    labels = %w(file_08 file_20 file_07 file_13)
    ordered_labels = %w(file_07 file_08 file_13 file_20)

    expect(labels.sort { |a,b| DRI::Sorters.trailing_digits_sort(a,b) }).to eq ordered_labels
  end

  it "should sort filenames by trailing digits with decimal points of unequal length" do
    labels = %w(DCLA.RDFA.006.08 DCLA.RDFA.006.13.01 DCLA.RDFA.006.20 DCLA.RDFA.006.07 DCLA.RDFA.006.13)
    ordered_labels = %w(DCLA.RDFA.006.07 DCLA.RDFA.006.08 DCLA.RDFA.006.13 DCLA.RDFA.006.13.01 DCLA.RDFA.006.20)

    expect(labels.sort { |a,b| DRI::Sorters.trailing_digits_sort(a,b) }).to eq ordered_labels
  end

  it "should handle equal substrings" do
    labels = %w(DCLA.RDFA.027.01.11 DCLA.RDFA.027.01.11.01)
    ordered_labels = %w(DCLA.RDFA.027.01.11 DCLA.RDFA.027.01.11.01)

    expect(labels.sort { |a,b| DRI::Sorters.trailing_digits_sort(a,b) }).to eq ordered_labels
  end

  it "should handle equal strings" do
    labels = %w(DCLA.RDFA.027.01.11 DCLA.RDFA.027.01.11)
    ordered_labels = %w(DCLA.RDFA.027.01.11 DCLA.RDFA.027.01.11)

    expect(labels.sort { |a,b| DRI::Sorters.trailing_digits_sort(a,b) }).to eq ordered_labels
  end

  it "should handle strings that can't be sorted by digits" do
    labels = %w(KDW_EX_32_09r_01.jpg  KDW_EX_32_09v_01.jpg)
    ordered_labels = %w(KDW_EX_32_09r_01.jpg  KDW_EX_32_09v_01.jpg)

    expect(labels.sort { |a,b| DRI::Sorters.trailing_digits_sort(a,b) }).to eq ordered_labels
  end

end
