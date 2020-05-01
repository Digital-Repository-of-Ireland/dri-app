Given /^(?:|I )choose to clear all bookmarks$/ do 
  accept_confirm do  
    element = page.find_link(link_to_id('clear bookmarks'), { visible: false})
    page.execute_script("return arguments[0].click();", element)
  end
end
