module Utils

  def numeric?(number)
    Integer(number) rescue false
  end

end
