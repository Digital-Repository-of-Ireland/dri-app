module PathDefine
  def cc_fixture_path
    @cc_fixture_path ||= "#{::Rails.root}/spec/fixtures"
  end
end

World(PathDefine)
