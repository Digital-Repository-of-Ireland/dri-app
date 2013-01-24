module UserInterface
  class Interface
    include Capybara::DSL
    include Capybara::RSpecMatchers

    def is_link?(link_id)
      page.should have_link(link_id)
    end

    def follow_link(link_id)
      click_link(link_id)
    end
  end

  def interface
    @interface ||= Interface.new
  end
end
World(UserInterface)
