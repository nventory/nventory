class HardwareProfilesController < ApplicationController
  # GET /hardware_profiles
  # GET /hardware_profiles.xml
  def index
    sort = case @params['sort']
           when "name" then "hardware_profiles.name"
           when "name_reverse" then "hardware_profiles.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "hardware_profiles.name"
    end
    
    @objects_pages = Paginator.new self, HardwareProfile.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = HardwareProfile.find_by_sql(["SELECT hardware_profiles.* FROM hardware_profiles " + 
                              " WHERE hardware_profiles.deleted_at IS NULL " +
                              " ORDER BY #{sort} " + 
                              " LIMIT ?,? ",
                              @objects_pages.current.offset, @objects_pages.items_per_page])
    
    # NOTE: The use of #{sort} in the above string could be considered a security hole (SQL injection) if sort
    # every becomes defineable from an external source.
    # We use it here, because using the standard way will wrap it in single quotes and make the sql invalid
    
    respond_to do |format|
      format.html # index.rhtml
      format.js   { 
        render :partial => 'shared/results_table', :locals => { :total => @total, :pages => @objects_pages, :objects => @objects }, :layout => false
      }
      format.xml  { render :xml => @objects.to_xml }
    end
  end

  # GET /hardware_profiles/1
  # GET /hardware_profiles/1.xml
  def show
    @hardware_profile = HardwareProfile.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @hardware_profile.to_xml }
    end
  end

  # GET /hardware_profiles/new
  def new
    @hardware_profile = HardwareProfile.new
  end

  # GET /hardware_profiles/1;edit
  def edit
    @hardware_profile = HardwareProfile.find(params[:id])
  end

  # POST /hardware_profiles
  # POST /hardware_profiles.xml
  def create
    @hardware_profile = HardwareProfile.new(params[:hardware_profile])

    respond_to do |format|
      if @hardware_profile.save
        flash[:notice] = 'HardwareProfile was successfully created.'
        format.html { redirect_to hardware_profile_url(@hardware_profile) }
        format.xml  { head :created, :location => hardware_profile_url(@hardware_profile) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @hardware_profile.errors.to_xml }
      end
    end
  end

  # PUT /hardware_profiles/1
  # PUT /hardware_profiles/1.xml
  def update
    @hardware_profile = HardwareProfile.find(params[:id])

    respond_to do |format|
      if @hardware_profile.update_attributes(params[:hardware_profile])
        flash[:notice] = 'HardwareProfile was successfully updated.'
        format.html { redirect_to hardware_profile_url(@hardware_profile) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hardware_profile.errors.to_xml }
      end
    end
  end

  # DELETE /hardware_profiles/1
  # DELETE /hardware_profiles/1.xml
  def destroy
    @hardware_profile = HardwareProfile.find(params[:id])
    @hardware_profile.destroy

    respond_to do |format|
      format.html { redirect_to hardware_profiles_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenters/1;version_history
  def version_history
    @hardware_profile = HardwareProfile.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
