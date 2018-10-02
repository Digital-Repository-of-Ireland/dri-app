module UserTests
    describe UserGroup::User do
        before :each do
            @user_email = "text@example.com"
            @user_fname = "fname"
            @user_sname = "sname"
            @user_locale = "en"
            @user_password = "password"
            @user = User.create(:email => @user_email, :password => @user_password, :password_confirmation => @user_password, :locale => @user_locale, :first_name => @user_fname, :second_name => @user_sname) 
        end
        
        describe "#new" do
            it "takes six parameters and returns a UserGroup::User object" do
                @user.should be_an_instance_of UserGroup::User
            end
        end

        #User security additions
        describe "#to_s" do
            it "should return the users email" do
                @user.to_s.should == @user_email
            end
        end

        describe "#full_name" do
            it "should return the users name" do
                @user.full_name.should == @user_fname+" "+@user_sname
            end
        end

        describe "#is_admin?" do
            context "is an admin" do
                before :each do
                    group_admin = Group.find_or_create_by(name: SETTING_GROUP_ADMIN) do |group|
                        group.description = "admin group"
                    end
                    group_id = group_admin.id
                    membership = @user.join_group(group_id)
                    membership.approved_by = @user.id
                    membership.save
                end

                it "should return true" do
                    @user.is_admin?.should == true
                end
            end

            context "not an admin" do
                it "should not be true" do
                    @user.is_admin?.should be_falsey
                end
            end
        end

        describe "#member?" do
            before :each do
                @group = Group.create(name: "test group", description: "test group")
                @membership = @user.join_group(@group.id)
                @membership.approved_by = @user.id
                @membership.save 
            end
            context "valid member" do
                it "should be a member of the group" do
                    @user.member?(@group.id).should == true
                    
                end

                it "should not be a pending member of the group" do
                    @user.pending_member?(@group.id).should be_falsey
                end
            end
        end

        describe "#pending_member?" do
            before :each do
                @group = Group.create(name: "test group", description: "test group")
                @membership = @user.join_group(@group.id)
            end

            context "pending member" do
                it "should be a pending member of the group" do
                    @user.pending_member?(@group.id).should == true
                end

                it "should not be a member of the group" do
                    @user.member?(@group.id).should be_falsey
                end
            end        
        end

        describe "#join_group" do
            context "group exists" do
                before :each do
                    @group = Group.create(name: "test group", description: "test group")
                end

                it "should return a valid (pending) membership" do
                    membership = @user.join_group(@group.id)
                    membership.valid?.should == true
                    @user.pending_member?(@group.id).should == true
                end
            end

            context "invalid group" do
                it "should return an invalid membership" do
                    membership = @user.join_group(nil)
                    membership.valid?.should be false
                end
            end
        end

        describe "#leave_group" do
            before :each do
                @group = Group.create(name: "test group", description: "test group")
                @membership = @user.join_group(@group.id) 
            end

            context "leaving a group with full membership" do
                before :each do
                    @membership.approved_by = @user.id
                    @membership.save
                    @user.member?(@group.id).should == true
                end

                it "should remove the user from the group" do
                    @user.leave_group(@group.id)
                    @user.member?(@group_id).should be_falsey and @user.pending_member?(@group.id).should be_falsey
                end  
            end

            context "leave a group with partial membership" do
                before :each do
                    @user.pending_member?(@group.id).should == true
                end

                it "should remove the user from the group" do
                    @user.leave_group(@group.id)
                    @user.member?(@group_id).should be_falsey and @user.pending_member?(@group.id).should be_falsey
                end
            end
        end

        describe "#create_token" do
            before :each do
                @user.authentication_token = nil
                @user.token_creation_date = nil
            end
            it "should create a login token" do
                @user.authentication_token.should be_nil
                @user.create_token
                @user.authentication_token.empty?.should be false
            end
        end

        describe "#destroy_token" do
            before :each do
                @user.create_token
            end
            it "should delete the login token" do
                @user.authentication_token.should_not be_nil
                @user.token_creation_date.should_not be_nil

                @user.destroy_token

                @user.authentication_token.should be_nil
                @user.token_creation_date.should be_nil
            end
        end

        describe "#full_memberships" do
            before :each do
                @group = Group.create(name: "test group", description: "test group")
                @membership = @user.join_group(@group.id)
                @membership.approved_by = @user.id
                @membership.save

                @groupb = Group.create(name: "test group b", description: "test group b")
                @membershipb = @user.join_group(@groupb.id)
            end
            context "full memberships" do
                it "should be a full member of group a" do
                    @user.full_memberships.map(&:group_id).include?(@group.id).should ==  true                    
                end

                it "should not be a full member of group b" do
                    @user.full_memberships.map(&:group_id).include?(@groupb.id).should == false
                end
            end
        end

        describe "#pending_memberships" do
            before :each do
                @group = Group.create(name: "test group", description: "test group")
                @membership = @user.join_group(@group.id)
                @membership.approved_by = @user.id
                @membership.save

                @groupb = Group.create(name: "test group b", description: "test group b")
                @membershipb = @user.join_group(@groupb.id)
            end
            context "pending memberships" do
                it "should not be a pending member of group a" do
                    @user.pending_memberships.map(&:group_id).include?(@group.id).should == false                    
                end

                it "should be a pending member of group b" do
                    @user.pending_memberships.map(&:group_id).include?(@groupb.id).should == true
                end
            end
        end

        #User options additions
        describe "#set_locale" do
            before :each do
                @user.locale = "" 
            end
            it "should reset locale to default" do
                @user.locale.should == ""
                @user.set_locale
                @user.locale.should == I18n.locale.to_s
            end
        end

        describe "#set_view_level" do
            before :each do
                @user.view_level = 0
            end
            it "should set view level to public (1)" do
                @user.view_level.should == 0
                @user.set_view_level("public")
                @user.view_level.should == 1
            end
        end

        describe "#get_view_level" do
            before :each do
                @user.set_view_level("registered")
            end
            it "should return registered" do
                @user.get_view_level.should == "registered"
            end
        end
    end
end
