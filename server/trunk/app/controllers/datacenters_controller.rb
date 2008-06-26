class DatacentersController < ApplicationController
  # GET /datacenters
  # GET /datacenters.xml
  def index
    
    sort = case @params['sort']
           when "name" then "datacenters.name"
           when "name_reverse" then "datacenters.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "datacenters.name"
    end
    
    @objects_pages = Paginator.new self, Datacenter.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = Datacenter.find_by_sql(["SELECT datacenters.* FROM datacenters " + 
                              " WHERE datacenters.deleted_at IS NULL " +
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

  # GET /datacenters/1
  # GET /datacenters/1.xml
  def show
    @datacenter = Datacenter.find_with_deleted(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @datacenter.to_xml }
    end
  end

  # GET /datacenters/new
  def new
    @datacenter = Datacenter.new
  end

  # GET /datacenters/1;edit
  def edit
    @datacenter = Datacenter.find(params[:id])
  end

  # POST /datacenters
  # POST /datacenters.xml
  def create
    @datacenter = Datacenter.new(params[:datacenter])

    respond_to do |format|
      if @datacenter.save
        flash[:notice] = 'Datacenter was successfully created.'
        format.html { redirect_to datacenter_url(@datacenter) }
        format.xml  { head :created, :location => datacenter_url(@datacenter) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @datacenter.errors.to_xml }
      end
    end
  end

  # PUT /datacenters/1
  # PUT /datacenters/1.xml
  def update
    @datacenter = Datacenter.find(params[:id])

    respond_to do |format|
      if @datacenter.update_attributes(params[:datacenter])
        flash[:notice] = 'Datacenter was successfully updated.'
        format.html { redirect_to datacenter_url(@datacenter) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datacenter.errors.to_xml }
      end
    end
  end

  # DELETE /datacenters/1
  # DELETE /datacenters/1.xml
  def destroy
    @datacenter = Datacenter.find(params[:id])
    begin
      @datacenter.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to datacenter_url(@datacenter) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to datacenters_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenters/1;version_history
  def version_history
    @datacenter = Datacenter.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /racks/1;visualization
  def visualization
    @datacenter = Datacenter.find_with_deleted(params[:id])
  end
  
end
