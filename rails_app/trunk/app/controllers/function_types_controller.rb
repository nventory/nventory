class FunctionTypesController < ApplicationController
  # GET /function_types
  # GET /function_types.xml
  def index
    sort = case @params['sort']
           when "name" then "function_types.name"
           when "name_reverse" then "function_types.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "function_types.name"
    end
    
    @objects_pages = Paginator.new self, FunctionType.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = FunctionType.find_by_sql(["SELECT function_types.* FROM function_types " + 
                              " WHERE function_types.deleted_at IS NULL " +
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

  # GET /function_types/1
  # GET /function_types/1.xml
  def show
    @function_type = FunctionType.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @function_type.to_xml }
    end
  end

  # GET /function_types/new
  def new
    @function_type = FunctionType.new
  end

  # GET /function_types/1;edit
  def edit
    @function_type = FunctionType.find(params[:id])
  end

  # POST /function_types
  # POST /function_types.xml
  def create
    @function_type = FunctionType.new(params[:function_type])

    respond_to do |format|
      if @function_type.save
        flash[:notice] = 'FunctionType was successfully created.'
        format.html { redirect_to function_type_url(@function_type) }
        format.xml  { head :created, :location => function_type_url(@function_type) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @function_type.errors.to_xml }
      end
    end
  end

  # PUT /function_types/1
  # PUT /function_types/1.xml
  def update
    @function_type = FunctionType.find(params[:id])

    respond_to do |format|
      if @function_type.update_attributes(params[:function_type])
        flash[:notice] = 'FunctionType was successfully updated.'
        format.html { redirect_to function_type_url(@function_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @function_type.errors.to_xml }
      end
    end
  end

  # DELETE /function_types/1
  # DELETE /function_types/1.xml
  def destroy
    @function_type = FunctionType.find(params[:id])
    begin
      @function_type.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to function_type_url(@function_type) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to function_types_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /function_types/1;version_history
  def version_history
    @function_type = FunctionType.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
end
