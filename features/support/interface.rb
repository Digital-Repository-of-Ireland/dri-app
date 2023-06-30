module Interface

  class UserInterface
    include Capybara::DSL
    include Capybara::RSpecMatchers

    def enter_valid_metadata(title)
      within_fieldset('title') do
        fill_in("digital_object_title_1", :with => title)
      end
      within_fieldset('description') do
        fill_in("digital_object_description_1", :with => "Created using the web form")
      end
      within_fieldset('creation_date') do
        if (!page.has_field?("digital_object_creation_date_1"))
          click_link("Add Creation Date")
          page.should have_field("digital_object_creation_date_1")
        end
        fill_in("digital_object_creation_date_1", :with => "2013-01-16")
      end
      within_fieldset('creator') do
        fill_in("digital_object_creator_1", :with => "test@test.com")
      end
      within_fieldset('rights') do
        fill_in("digital_object_rights_1", :with => "This is a statement of rights")
      end
      within_fieldset('type') do
        if (page.has_select?("digital_object_type_1"))
          select "Sound", :from => "digital_object_type_1"
        else
          fill_in("digital_object_type_1", :with => "Sound")
        end
      end
    end

    def enter_invalid_metadata(title)
      within_fieldset('title') do
        fill_in("digital_object_title_1", :with => title)
      end
      within_fieldset('description') do
        fill_in("digital_object_description_1", :with => "Created using the web form")
      end
      within_fieldset('creation_date') do
        if (!page.has_field?("digital_object_creation_date_1"))
          click_link("Add Creation Date")
          page.should have_field("digital_object_creation_date_1")
        end
        fill_in("digital_object_creation_date_1", :with => "2013-01-16")
      end
      within_fieldset('rights') do
        fill_in("digital_object_rights_1", :with => "")
      end
      within_fieldset('type') do
        if (page.has_select?("digital_object_type_1"))
          select "Sound", :from => "digital_object_type_1"
        else
          fill_in("digital_object_type_1", :with => "Sound")
        end
      end
    end

    def enter_valid_pdf_metadata(title)
      within_fieldset('title') do
        fill_in("digital_object_title_1", :with => title)
      end
      within_fieldset('description') do
        fill_in("digital_object_description_1", :with => "Created using the web form")
      end
      within_fieldset('creation_date') do
        click_link("Add Creation Date")
        page.document.should have_field("digital_object_creation_date_1")
        fill_in("digital_object_creation_date", :with => "2013-01-16")
      end
      within_fieldset('rights') do
        fill_in("digital_object_rights_1", :with => "This is a statement of rights")
      end
      within_fieldset('type') do
        fill_in("digital_object_type_1", :with => "Text")
      end
    end

    def has_valid_metadata?
      within(:xpath, "//div[contains(concat(' ', @class, ' '), 'dri_object_container')]") do
      	page.should have_content("Creation Date 2013-01-16")
        page.should have_content("Title A Test Object")
        page.should have_content("Description Created using the web form")
        page.should have_content("Rights This is a statement of rights")
      end
    end

    def enter_modified_metadata
      within_fieldset('description') do
        fill_in("digital_object_description_1", :with => "Editing test")
      end
      within_fieldset('creation_date') do
        if (!page.has_field?("digital_object_creation_date_1"))
          click_link("Add Creation Date")
          page.should have_field("digital_object_creation_date_1")
        end
        fill_in("digital_object_creation_date_1", :with => "2013-01-01")
      end
    end

    def has_modified_metadata?
      within(:xpath, "//div[contains(concat(' ', @class, ' '), 'dri_object_container')]") do
        page.should have_content("Creation Date 2013-01-01")
        page.should have_content("Description Editing test")
      end
    end

    def has_rights_statement?
      within(:xpath, "//div[contains(concat(' ', @class, ' '), 'dri_object_container')]") do
        page.should have_content("Rights This is a statement of rights")
      end
    end

    def has_licence?
     page.should have_content("Licence")
    end

    def is_format?(format)
      within(:xpath, "//div[contains(concat(' ', @class, ' '), 'dri_object_container')]") do
        page.should have_content("Format #{format}")
      end
    end

    def is_type?(type)
      within(:xpath, "//div[contains(concat(' ', @class, ' '), 'dri_object_container')]") do
        page.should have_content("Types #{type}")
      end
    end

    def enter_valid_licence(name)
      fill_in("licence[name]", :with => name)
      fill_in("licence[url]", :with => "http://www.dri.ie/")
      fill_in("licence[description]", :with => "Valid Description")
    end
  end

  def interface
    @user_interface ||= UserInterface.new
  end

end
World(Interface)
