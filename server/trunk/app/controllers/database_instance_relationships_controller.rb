class DatabaseInstanceRelationshipsController < ApplicationController
  # GET /database_instance_relationships
  # GET /database_instance_relationships.xml
  def index
    sort = case @params['sort']
           when "name" then "database_instance_relationships.name"
           when "name_reverse" then "database_instance_relationships.name DESC"
           when "assigned_at" then "database_instance_relationships.assigned_at"
           when "assigned_at_reverse" then "database_instance_relationships.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "database_instance_relationships.name"
    end
    
    @objects_pages = Paginator.new self, DatabaseInstanceRelationship.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = DatabaseInstanceRelationship.find_by_sql(["SELECT database_instance_relationships.* FROM database_instance_relationships " + 
                              " WHERE database_instance_relationships.deleted_at IS NULL " +
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
  
  

  # GET /database_instance_relationships/1
  # GET /database_instance_relationships/1.xml
  def show
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @database_instance_relationship.to_xml }
    end
  end

  # GET /database_instance_relationships/new
  def new
    @database_instance_relationship = DatabaseInstanceRelationship.new
  end

  # GET /database_instance_relationships/1;edit
  def edit
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])
  end

  # POST /database_instance_relationships
  # POST /database_instance_relationships.xml
  def create
    @database_instance_relationship = DatabaseInstanceRelationship.new(params[:database_instance_relationship])

    respond_to do |format|
      if @database_instance_relationship.save
        flash[:notice] = 'DatabaseInstanceRelationship was successfully created.'
        format.html { redirect_to database_instance_relationship_url(@database_instance_relationship) }
        format.xml  { head :created, :location => database_instance_relationship_url(@database_instance_relationship) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @database_instance_relationship.errors.to_xml }
      end
    end
  end

  # PUT /database_instance_relationships/1
  # PUT /database_instance_relationships/1.xml
  def update
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])

    respond_to do |format|
      if @database_instance_relationship.update_attributes(params[:database_instance_relationship])
        flash[:notice] = 'DatabaseInstanceRelationship was successfully updated.'
        format.html { redirect_to database_instance_relationship_url(@database_instance_relationship) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @database_instance_relationship.errors.to_xml }
      end
    end
  end

  # DELETE /database_instance_relationships/1
  # DELETE /database_instance_relationships/1.xml
  def destroy
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])
    @database_instance_relationship.destroy

    respond_to do |format|
      format.html { redirect_to database_instance_relationships_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /environment_node_assignments/1;version_history
  def version_history
    @database_instance_relationship = DatabaseInstanceRelationship.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
