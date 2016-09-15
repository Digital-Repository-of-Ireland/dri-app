class ReadersController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  include DRI::Readable

  # Manage the read access requests
  def index
    enforce_permissions!('manage_collection', params[:id])

    @collection = retrieve_object!(params[:id])
    @group = UserGroup::Group.find_by(name: params[:id])

    @pending_memberships = @group.pending_memberships.page(params[:page])
    @memberships = @group.full_memberships.page(params[:page])
  end

  # User requesting read access to collection
  def create
    @collection = retrieve_object!(params[:id])
    @reader_group = governing_reader_group(@collection.id)

    unless @reader_group
      flash[:alert] = t('dri.flash.error.no_read_group')
      redirect_to :back
      return
    end

    action = current_user.join_group(@reader_group.id)
    if action.errors.count > 0
      flash[:alert] = t('dri.flash.error.submitting_read_request',
                      error: action.errors.full_messages.inspect)
      redirect_to :back
      return
    end

    store_request_form(@reader_group.id)
    notify_managers(@reader_group)

    flash[:success] = t('dri.flash.notice.request_form_submitted')
    redirect_to :back
  end

  # Display the read request form
  def show
    enforce_permissions!('manage_collection', params[:id])

    group = UserGroup::Group.find_by(name: params[:id])
    @membership = UserGroup::Membership.find_by(group_id: group.id, user_id: params[:user_id])
 
    respond_to do |format|
      format.js
    end
  end

  # Approve the read request
  def update
    enforce_permissions!('manage_collection', params[:id])

    @collection = retrieve_object!(params[:id])

    group = UserGroup::Group.find_by(name: params[:id])
    membership = UserGroup::Membership.find_by(group_id: group.id, user_id: params[:user_id])

    user = User.find(membership.user_id)

    if(approve_membership(membership))
      flash[:success] = t("dri.flash.notice.read_access_approved")
      AuthMailer.approved_mail(user, group, @collection.title.first).deliver_now
    else
      flash[:error] = t("dri.flash.error.read_access_approved")
    end
    
    redirect_to :back
  end

  # Remove read access, approved or pending
  def destroy
    enforce_permissions!('manage_collection', params[:id])

    @collection = retrieve_object!(params[:id])

    group = UserGroup::Group.find_by(name: params[:id])
    membership = UserGroup::Membership.find_by(group_id: group.id, user_id: params[:user_id])
    user = User.find(membership.user_id)

    action = user.leave_group(group.id) unless group.nil? || group.name==SETTING_GROUP_DEFAULT
    if action.nil? || action == false
      flash[:error] = t("user_groups.memberships.errors.membership")
    else
      if membership.approved?
        flash[:success] = t("dri.flash.notice.read_access_removed")
        AuthMailer.removed_mail(user, group, @collection.title.first).deliver_now
      else
        flash[:success] = t("dri.flash.notice.read_access_rejected")
        AuthMailer.rejected_mail(user, group, @collection.title.first).deliver_now
      end
    end

    redirect_to :back
  end

  private

    def approve_membership(application)
      application.approve_membership(current_user.id)
      application.save
    end

    def notify_managers(group)
      # inform managers for reader group requests
      result = ActiveFedora::SolrService.query("id:#{@collection.id}")
      doc = SolrDocument.new(result.pop) if result.count > 0
      managers = doc[Solrizer.solr_name('manager_access_person', :stored_searchable, type: :symbol)]

      # if no manager set for this collection it could be inherited, iterate up the tree
      if managers.nil?
        doc[Solrizer.solr_name('ancestor_id', :stored_searchable, type: :text)].reverse_each do |ancestor|
          result = ActiveFedora::SolrService.query("id:#{ancestor}")
          ancestordoc = SolrDocument.new(result.pop) if result.count > 0
          managers = ancestordoc[Solrizer.solr_name('manager_access_person', :stored_searchable, type: :symbol)]
          break if managers.present? && managers.count > 0
        end
      end

      if managers.present? && managers.count > 0
        AuthMailer.pending_mail(managers, current_user.email,
        collection_manage_requests_url(group.name)).deliver_now
      end
    end

    def store_request_form(group_id)
      membership = current_user.memberships.find_by(group_id: group_id)

      membership.request_form[:name] = params[:name] if params[:name].present?
      membership.request_form[:organisation] = params[:organisation] if params[:organisation].present?
      membership.request_form[:position] = params[:position] if params[:position].present?

      if params[:use].present?
        use = {}
        case params[:use]
        when 'academic'
          use[:academic] = {}
          use[:academic][:project] = params[:academic_project] if params[:academic_project].present?
          use[:academic][:funder] = params[:academic_funder] if params[:academic_funder].present?
          use[:academic][:investigator] = params[:academic_investigators] if params[:academic_investigators].present?
        when 'research'
          use[:research] = {}
          use[:research][:description] = params[:research_description] if params[:research_description].present?
        when 'education'
          use[:education] = {}
          use[:education][:role] = params[:teaching_role] if params[:teaching_role].present?
          use[:education][:module] = params[:teaching_module] if params[:teaching_module].present?
          use[:education][:dates] = params[:teaching_dates] if params[:teaching_dates].present?
        when 'commercial'
          use[:commercial] = {}
          use[:commercial][:description] = params[:commercial_description] if params[:commercial_description].present?
        when 'other'
          use[:other] = {}
          use[:other][:description] = params[:other_description] if params[:other_description].present?
        end

        membership.request_form[:use] = use.to_json
      end

      membership.save
    end
end
