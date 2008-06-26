class StatusesController < ApplicationController
  # GET /statuses
  # GET /statuses.xml
  def index
    sort = case @params['sort']
           when "name" then "statuses.name"
           when "name_reverse" then "statuses.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "statuses.name"
    end
    
    @objects_pages = Paginator.new self, Status.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = Status.find_by_sql(["SELECT statuses.* FROM statuses " + 
                              " WHERE statuses.deleted_at IS NULL " +
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

  # GET /statuses/1
  # GET /statuses/1.xml
  def show
    @status = Status.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @status.to_xml }
    end
  end

  # GET /statuses/new
  def new
    @status = Status.new
  end

  # GET /statuses/1;edit
  def edit
    @status = Status.find(params[:id])
  end

  # POST /statuses
  # POST /statuses.xml
  def create
    @status = Status.new(params[:status])

    respond_to do |format|
      if @status.save
        flash[:notice] = 'Status was successfully created.'
        format.html { redirect_to status_url(@status) }
        format.xml  { head :created, :location => status_url(@status) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @status.errors.to_xml }
      end
    end
  end

  # PUT /statuses/1
  # PUT /statuses/1.xml
  def update
    @status = Status.find(params[:id])

    respond_to do |format|
      if @status.update_attributes(params[:status])
        flash[:notice] = 'Status was successfully updated.'
        format.html { redirect_to status_url(@status) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @status.errors.to_xml }
      end
    end
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.xml
  def destroy
    @status = Status.find(params[:id])
    @status.destroy

    respond_to do |format|
      format.html { redirect_to statuses_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /statuses/1;version_history
  def version_history
    @status = Status.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
