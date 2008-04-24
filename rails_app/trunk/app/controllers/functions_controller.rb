class FunctionsController < ApplicationController
  # GET /functions
  # GET /functions.xml
  def index
    sort = case @params['sort']
           when "name" then "functions.name"
           when "name_reverse" then "functions.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "functions.name"
    end
    
    @objects_pages = Paginator.new self, Function.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = Function.find_by_sql(["SELECT functions.* FROM functions " + 
                              " WHERE functions.deleted_at IS NULL " +
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

  # GET /functions/1
  # GET /functions/1.xml
  def show
    @function = Function.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @function.to_xml }
    end
  end

  # GET /functions/new
  def new
    @function = Function.new
    respond_to do |format|
      format.html # show.rhtml
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /functions/1;edit
  def edit
    @function = Function.find(params[:id])
  end

  # POST /functions
  # POST /functions.xml
  def create
    @function = Function.new(params[:function])

    respond_to do |format|
      if @function.save
        format.html { 
          flash[:notice] = 'Function was successfully created.'
          redirect_to function_url(@function) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_function_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'node', :to => 'function' }
            page['node_function_assignment_function_id'].value = @function.id
            page.hide 'new_function'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_function_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
            
          }
        }
        format.xml  { head :created, :location => function_url(@function) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@function.errors.full_messages) } }
        format.xml  { render :xml => @function.errors.to_xml }
      end
    end
  end

  # PUT /functions/1
  # PUT /functions/1.xml
  def update
    @function = Function.find(params[:id])

    respond_to do |format|
      if @function.update_attributes(params[:function])
        flash[:notice] = 'Function was successfully updated.'
        format.html { redirect_to function_url(@function) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @function.errors.to_xml }
      end
    end
  end

  # DELETE /functions/1
  # DELETE /functions/1.xml
  def destroy
    @function = Function.find(params[:id])
    begin
      @function.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to function_url(@function) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to functions_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /functions/1;version_history
  def version_history
    @function = Function.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
