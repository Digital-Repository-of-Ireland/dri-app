require 'ffaker'
module Seeds
  INSTITUE_NAMES = %w(test_institute other_test_institute last_test_institute)

  def self.add_organisations
    INSTITUE_NAMES.each do |institute_name|
      test_institute = Institute.new(
        name: institute_name,
        url: FFaker::Internet.domain_name,
        logo: 'fake_logo.png',
        depositing: true
      )
      test_institute.save
    end
  end

  def self.remove_organisations
    INSTITUE_NAMES.each do |institute_name|
      Institute.find_by(name: institute_name).destroy!
    end
  end
end
