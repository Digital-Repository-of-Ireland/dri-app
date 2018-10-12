require 'ffaker'
module Seeds
  INSTITUE_NAMES = %w(test_institute other_test_institute last_test_institute)

  def self.add_organisations
    create_organisation('save')
  end

  def self.add_organisations!
    create_organisation('save!')
  end

  def self.remove_organisations
    destroy_organisation('destroy')
  end

  def self.remove_organisations!
    destroy_organisation('destroy!')
  end

  private

  # @param func [String] callback to save institute
  def self.create_organisation(func)
    INSTITUE_NAMES.each do |institute_name|
      test_institute = Institute.new(
        name: institute_name,
        url: FFaker::Internet.domain_name,
        logo: 'fake_logo.png',
        depositing: true
      )
      test_institute.send(func)
    end
  end

  # @param func [String] callback to destroy institute
  def self.destroy_organisation(func)
    INSTITUE_NAMES.each do |institute_name|
      Institute.find_by(name: institute_name).send(func)
    end
  end
end
