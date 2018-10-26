module DRI::Sorters

  def self.trailing_digits_sort(a, b)
    return 0 if a == b

    index = a.chars.each_with_index do |char, index|
      break index if char != b[index]

      # all of a is contained in b
      break -1 if index == (a.length - 1)
    end

    #all of a is in b so b is greater
    return index if index == -1

    digits_a = a[index..-1].scan(/\d+/).map(&:to_i)
    digits_b = b[index..-1].scan(/\d+/).map(&:to_i)

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
