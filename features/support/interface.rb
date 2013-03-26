module Interface

  class UserInterface
    include Capybara::DSL
    include Capybara::RSpecMatchers
    
    def enter_valid_metadata
      within_fieldset('metadata') do
        fill_in("dri_model_title", :with => "A Test Object")
        fill_in("dri_model_description", :with => "Created using the web form")
        fill_in("dri_model_broadcast_date", :with => "2013-01-16")
        fill_in("dri_model_rights", :with => "This is a statement of rights")
      end
    end

    def has_valid_metadata?
      within(:xpath, "//div[@id='document']") do
      	page.should have_content("Broadcast Date: 2013-01-16")
        page.should have_content("Title: A Test Object")
        page.should have_content("Description: Created using the web form")
        page.should have_content("Rights: This is a statement of rights")
      end
    end

    def enter_modified_metadata
      within_fieldset('metadata') do
        fill_in("dri_model_description", :with => "Editing test")
        fill_in("dri_model_broadcast_date", :with => "2013-01-01")
      end
    end

    def has_modified_metadata?
      within(:xpath, "//div[@id='document']") do
        page.should have_content("Broadcast Date: 2013-01-01")
        page.should have_content("Description: Editing test")
      end
    end

    def has_rights_statement?
      within(:xpath, "//div[@id='document']") do
        page.should have_content("Rights: This is a statement of rights")
      end
    end

    def has_licence?
     page.should have_content("Licence")
    end

    def is_format?(format)
      within(:xpath, "//div[@id='document']") do
        page.should have_content("Format: #{format}")
      end
    end
      
  end

  def interface
    @user_interface ||= UserInterface.new
  end

end
World(Interface)
