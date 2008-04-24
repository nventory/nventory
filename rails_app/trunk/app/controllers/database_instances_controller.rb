class DatabaseInstancesController < ApplicationController
  # GET /database_instances
  # GET /database_instances.xml
  def index
    sort = case @params['sort']
           when "name" then "database_instances.name"
           when "name_reverse" then "database_instances.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "database_instances.name"
    end
    
    @objects_pages = Paginator.new self, DatabaseInstance.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = DatabaseInstance.find_by_sql(["SELECT database_instances.* FROM database_instances " + 
                              " WHERE database_instances.deleted_at IS NULL " +
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

  # GET /database_instances/1
  # GET /database_instances/1.xml
  def show
    @database_instance = DatabaseInstance.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @database_instance.to_xml }
    end
  end

  # GET /database_instances/new
  def new
    @database_instance = DatabaseInstance.new
    respond_to do |format|
      format.html # show.rhtml
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /database_instances/1;edit
  def edit
    @database_instance = DatabaseInstance.find(params[:id])
  end

  # POST /database_instances
  # POST /database_instances.xml
  def create
    @database_instance = DatabaseInstance.new(params[:database_instance])

    respond_to do |format|
      if @database_instance.save
        format.html { 
          flash[:notice] = 'Database Instance was successfully created.'
          redirect_to database_instance_url(@database_instance) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_database_instance_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'node', :to => 'database_instance' }
            page['node_database_instance_assignment_database_instance_id'].value = @database_instance.id
            page.hide 'new_database_instance'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_database_instance_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
          }
        }
        format.xml  { head :created, :location => database_instance_url(@database_instance) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@database_instance.errors.full_messages) } }
        format.xml  { render :xml => @database_instance.errors.to_xml }
      end
    end
  end

  # PUT /database_instances/1
  # PUT /database_instances/1.xml
  def update
    @database_instance = DatabaseInstance.find(params[:id])

    respond_to do |format|
      if @database_instance.update_attributes(params[:database_instance])
        flash[:notice] = 'DatabaseInstance was successfully updated.'
        format.html { redirect_to database_instance_url(@database_instance) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @database_instance.errors.to_xml }
      end
    end
  end

  # DELETE /database_instances/1
  # DELETE /database_instances/1.xml
  def destroy
    @database_instance = DatabaseInstance.find(params[:id])
    @database_instance.destroy

    respond_to do |format|
      format.html { redirect_to database_instances_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /database_instances/1;version_history
  def version_history
    @database_instance = DatabaseInstance.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
