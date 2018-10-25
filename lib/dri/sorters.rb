module DRI::Sorters

  def self.trailing_digits_sort(a, b)
    if a == b
      0
    else
      index = a.chars.each_with_index do |char, index|
        break index if char != b[index]

        # all of a is contained in b
        break -1 if index == (a.length - 1)
      end

      # a is shorter than b
      if index == -1
        -1
      else
        digits_a = a[index..-1].scan(/\d+/).map(&:to_i)
        digits_b = b[index..-1].scan(/\d+/).map(&:to_i)

        rc = digits_a.each_with_index do |num, index|
          break 1 unless digits_b[index]

          if num != digits_b[index]
            break num - digits_b[index]
          end
        end

        rc ? rc : -1
      end
    end
  end

end
