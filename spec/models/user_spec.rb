require 'spec_helper'

module UserA
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
                    group_admin = Group.create(name: SETTING_ADMIN_GROUP, description: "admin group")
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
                    @user.is_admin?.should be_false
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
                    @user.pending_member?(@group.id).should be_false
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
                    @user.member?(@group.id).should be_false
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
                    membership.valid?.should be_false
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
                    @user.member?(@group_id).should be_false and @user.pending_member?(@group.id).should be_false
                end  
            end

            context "leave a group with partial membership" do
              before :each do
                    @user.pending_member?(@group.id).should == true
                end

                it "should remove the user from the group" do
                    @user.leave_group(@group.id)
                    @user.member?(@group_id).should be_false and @user.pending_member?(@group.id).should be_false
                end
            end
        end


        #full_memberships

        #pending memberships

        #User options additions
        #set_locale

        #set_view_level

        #get_view_level
        
        #about_me

    end
end