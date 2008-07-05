class FunctionTypesController < ApplicationController
  # GET /function_types
  # GET /function_types.xml
  def index
    sort = case params['sort']
           when "name" then "function_types.name"
           when "name_reverse" then "function_types.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = FunctionType.default_search_attribute
      sort = 'function_types.' + FunctionType.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = FunctionType.find(:all, :order => sort)
    else
      @objects = FunctionType.paginate(:all,
                                       :order => sort,
                                       :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /function_types/1
  # GET /function_types/1.xml
  def show
    @function_type = FunctionType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @function_type.to_xml(:dasherize => false) }
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
        format.xml  { render :xml => @function_type.errors.to_xml, :status => :unprocessable_entity }
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
        format.xml  { render :xml => @function_type.errors.to_xml, :status => :unprocessable_entity }
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
