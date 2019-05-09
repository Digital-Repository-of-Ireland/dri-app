module LoginHelper
  include Warden::Test::Helpers
  # use Warden::Test::Helpers.login_as for efficiency
  def with_login(login, password: 'password', locale: 'en')
    email = "#{login}@#{login}.com"
    image_path = File.join(cc_fixture_path, 'sample_image.png')

    # modifying factorybot object is slow than making real user
    # TODO: add params to user factory and check if it's faster
    # @user = FactoryBot.create(:user)
    # @user.email = email
    # @user.password = password
    # @user.locale = locale
    # @user.save
    @user = User.find_by_email(email)
    @user ||= User.create(email: email, password: password, password_confirmation: password,
                          locale: locale, first_name: "fname", second_name: "sname",
                          image_link: image_path)
    @user.confirm
    @user.save
    yield(@user) if block_given?
    login_as @user
  end

  # login by manually entering data into the webform
  def with_web_login(login, password: 'password', locale: 'en')
    email = "#{login}@#{login}.com"
    image_path = File.join(cc_fixture_path, 'sample_image.png')

    @user = User.find_by_email(email)
    @user ||= User.create(email: email, password: password, password_confirmation: password,
                          locale: locale, first_name: "fname", second_name: "sname",
                          image_link: image_path)
    @user.confirm
    @user.save
    delete destroy_user_session_path(@user)
    visit path_to("sign in")
    yield(@user) if block_given?
    fill_in("user_email", :with => email)
    fill_in("user_password", :with => "password")
    click_button("Login")
  end
end

World(LoginHelper)
