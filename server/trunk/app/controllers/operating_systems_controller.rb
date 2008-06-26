class OperatingSystemsController < ApplicationController
  # GET /operating_systems
  # GET /operating_systems.xml
  def index
    sort = case @params['sort']
           when "name" then "operating_systems.name"
           when "name_reverse" then "operating_systems.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "operating_systems.name"
    end
    
    @objects_pages = Paginator.new self, OperatingSystem.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = OperatingSystem.find_by_sql(["SELECT operating_systems.* FROM operating_systems " + 
                              " WHERE operating_systems.deleted_at IS NULL " +
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

  # GET /operating_systems/1
  # GET /operating_systems/1.xml
  def show
    @operating_system = OperatingSystem.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @operating_system.to_xml }
    end
  end

  # GET /operating_systems/new
  def new
    @operating_system = OperatingSystem.new
  end

  # GET /operating_systems/1;edit
  def edit
    @operating_system = OperatingSystem.find(params[:id])
  end

  # POST /operating_systems
  # POST /operating_systems.xml
  def create
    @operating_system = OperatingSystem.new(params[:operating_system])

    respond_to do |format|
      if @operating_system.save
        flash[:notice] = 'OperatingSystem was successfully created.'
        format.html { redirect_to operating_system_url(@operating_system) }
        format.xml  { head :created, :location => operating_system_url(@operating_system) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @operating_system.errors.to_xml }
      end
    end
  end

  # PUT /operating_systems/1
  # PUT /operating_systems/1.xml
  def update
    @operating_system = OperatingSystem.find(params[:id])

    respond_to do |format|
      if @operating_system.update_attributes(params[:operating_system])
        flash[:notice] = 'OperatingSystem was successfully updated.'
        format.html { redirect_to operating_system_url(@operating_system) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @operating_system.errors.to_xml }
      end
    end
  end

  # DELETE /operating_systems/1
  # DELETE /operating_systems/1.xml
  def destroy
    @operating_system = OperatingSystem.find(params[:id])
    @operating_system.destroy

    respond_to do |format|
      format.html { redirect_to operating_systems_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /operating_systems/1;version_history
  def version_history
    @operating_system = OperatingSystem.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
