module Interface

  class UserInterface
    include Capybara::DSL
    include Capybara::RSpecMatchers

    def enter_valid_metadata(title)
      within_fieldset('title') do
        fill_in("batch_title][", :with => title)
      end
      within_fieldset('description') do
        fill_in("batch_description][", :with => "Created using the web form")
      end
      within_fieldset('creation_date') do
        if (!page.has_field?("batch_creation_date]["))
          click_link("Add Creation Date")
          page.should have_field("batch_creation_date][")
        end
        fill_in("batch_creation_date][", :with => "2013-01-16")
      end
      within_fieldset('rights') do
        fill_in("batch_rights][", :with => "This is a statement of rights")
      end
      within_fieldset('type') do
        fill_in("batch_type][", :with => "Sound")
      end
    end

    def enter_invalid_metadata(title)
      within_fieldset('title') do
        fill_in("batch_title][", :with => title)
      end
      within_fieldset('description') do
        fill_in("batch_description][", :with => "Created using the web form")
      end
      within_fieldset('creation_date') do
        if (!page.has_field?("batch_creation_date]["))
          click_link("Add Creation Date")
          page.should have_field("batch_creation_date][")
        end
        fill_in("batch_creation_date][", :with => "2013-01-16")
      end
      within_fieldset('rights') do
        fill_in("batch_rights][", :with => "")
      end
      within_fieldset('type') do
        fill_in("batch_type][", :with => "Sound")
      end
    end

    def enter_valid_pdf_metadata(title)
      within_fieldset('title') do
        fill_in("batch_title][", :with => title)
      end
      within_fieldset('description') do
        fill_in("batch_description][", :with => "Created using the web form")
      end
      within_fieldset('creation_date') do
        click_link("Add Creation Date")
        page.document.should have_field("batch_creation_date][")
        fill_in("batch_creation_date][", :with => "2013-01-16")
      end
      within_fieldset('rights') do
        fill_in("batch_rights][", :with => "This is a statement of rights")
      end
      within_fieldset('type') do
        fill_in("batch_type][", :with => "Text")
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
        fill_in("batch_description][", :with => "Editing test")
      end
      within_fieldset('creation_date') do
        if (!page.has_field?("batch_creation_date]["))
          click_link("Add Creation Date")
          page.should have_field("batch_creation_date][")
        end
        fill_in("batch_creation_date][", :with => "2013-01-01")
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
        page.should have_content("Type #{type}")
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
