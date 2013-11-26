module CustomMatchers

 def select_by_value(opt_value, options={})
    if options.has_key?(:from)
      find(:select, options[:from]).find(:xpath, ".//option[@value='#{opt_value}']").select_option
    elsif options.has_key?(:xpath)
      find(:xpath, options[:xpath]).find(:xpath, ".//option[@value='#{opt_value}']").select_option
    else
      find(:xpath, "./option[@value='#{opt_value}']").select_option
    end
  end

end

World(CustomMatchers)
