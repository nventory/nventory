class OutletsController < ApplicationController
  # GET /outlets
  # GET /outlets.xml
  def index
    sort = case @params['sort']
           when "name" then "outlets.name"
           when "name_reverse" then "outlets.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "outlets.name"
    end
    
    @objects_pages = Paginator.new self, Outlet.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = Outlet.find_by_sql(["SELECT outlets.* FROM outlets " + 
                              " WHERE outlets.deleted_at IS NULL " +
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

  # GET /outlets/1
  # GET /outlets/1.xml
  def show
    @outlet = Outlet.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @outlet.to_xml }
    end
  end

  # GET /outlets/new
  def new
    @outlet = Outlet.new
  end

  # GET /outlets/1;edit
  def edit
    @outlet = Outlet.find(params[:id])
    respond_to do |format|
      format.html # show.rhtml
      format.js  { render :action => 'inline_consumer_edit', :layout => false }
    end
  end

  # POST /outlets
  # POST /outlets.xml
  def create
    @outlet = Outlet.new(params[:outlet])

    respond_to do |format|
      if @outlet.save
        flash[:notice] = 'Outlet was successfully created.'
        format.html { redirect_to outlet_url(@outlet) }
        format.xml  { head :created, :location => outlet_url(@outlet) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @outlet.errors.to_xml }
      end
    end
  end

  # PUT /outlets/1
  # PUT /outlets/1.xml
  def update
    @outlet = Outlet.find(params[:id])

    respond_to do |format|
      if @outlet.update_attributes(params[:outlet])
        flash[:notice] = 'Outlet was successfully updated.'
        format.html { redirect_to outlet_url(@outlet) }
        format.js { 
          render(:update) { |page| 
            page.replace_html dom_id(@outlet), :partial => 'consumer', :locals => { :outlet => @outlet }
          }
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js   { render(:update) { |page| page.alert(@outlet.errors.full_messages) } }
        format.xml  { render :xml => @outlet.errors.to_xml }
      end
    end
  end

  # DELETE /outlets/1
  # DELETE /outlets/1.xml
  def destroy
    @outlet = Outlet.find(params[:id])
    @outlet.destroy

    respond_to do |format|
      format.html { redirect_to outlets_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /outlets/1;version_history
  def version_history
    @outlet = Outlet.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /outlets/1;version_history
  def consumer
    @outlet = Outlet.find(params[:id])
    render :action => '_consumer', :layout => false
  end
  
end
