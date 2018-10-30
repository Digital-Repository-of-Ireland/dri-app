module DRI::Sorters

  def self.trailing_digits_sort(a, b)
    return 0 if a == b

    split_a = a.match(/[0-9\._]*$/)
    split_b = b.match(/[0-9\._]*$/)

    return (a <=> b) unless split_a[0].present? && split_b[0].present?

    digits_a = split_a[0].scan(/\d+/).map(&:to_i)
    digits_b = split_b[0].scan(/\d+/).map(&:to_i)

    # can't sort on digits so fallback to sort strings
    return (a <=> b) if digits_a == digits_b

    digits_a.each_with_index do |num, index|
      # a longer than b, so a greater
      return 1 unless digits_b[index]

      if num != digits_b[index]
        return num - digits_b[index]
      end
    end

    # a shorter than b, so b greater
    -1
  end
end
