class NodeDatabaseInstanceAssignmentsController < ApplicationController
  # GET /node_database_instance_assignments
  # GET /node_database_instance_assignments.xml
  def index
    sort = case @params['sort']
           when "assigned_at" then "node_database_instance_assignments.assigned_at"
           when "assigned_at_reverse" then "node_database_instance_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "assigned_at"
      sort = "node_database_instance_assignments.assigned_at"
    end
    
    @objects_pages = Paginator.new self, NodeDatabaseInstanceAssignment.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = NodeDatabaseInstanceAssignment.find_by_sql(["SELECT node_database_instance_assignments.* FROM node_database_instance_assignments " + 
                              " WHERE node_database_instance_assignments.deleted_at IS NULL " +
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

  # GET /node_database_instance_assignments/1
  # GET /node_database_instance_assignments/1.xml
  def show
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @node_database_instance_assignment.to_xml }
    end
  end

  # GET /node_database_instance_assignments/new
  def new
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.new
  end

  # GET /node_database_instance_assignments/1;edit
  def edit
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.find(params[:id])
  end

  # POST /node_database_instance_assignments
  # POST /node_database_instance_assignments.xml
  def create
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.new(params[:node_database_instance_assignment])

    respond_to do |format|
      if @node_database_instance_assignment.save
        format.html { 
          flash[:notice] = 'NodeDatabaseInstanceAssignment was successfully created.'
          redirect_to node_database_instance_assignment_url(@node_database_instance_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'node_database_instance_assignments', :partial => 'nodes/database_instance_assignments', :locals => { :node => @node_database_instance_assignment.node }
            page.hide 'create_database_instance_assignment'
            page.show 'add_database_instance_assignment_link'
          }
        }
        format.xml  { head :created, :location => node_database_instance_assignment_url(@node_database_instance_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_database_instance_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_database_instance_assignment.errors.to_xml }
      end
    end
  end

  # PUT /node_database_instance_assignments/1
  # PUT /node_database_instance_assignments/1.xml
  def update
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.find(params[:id])

    respond_to do |format|
      if @node_database_instance_assignment.update_attributes(params[:node_database_instance_assignment])
        flash[:notice] = 'NodeDatabaseInstanceAssignment was successfully updated.'
        format.html { redirect_to node_database_instance_assignment_url(@node_database_instance_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_database_instance_assignment.errors.to_xml }
      end
    end
  end

  # DELETE /node_database_instance_assignments/1
  # DELETE /node_database_instance_assignments/1.xml
  def destroy
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.find(params[:id])
    @node = @node_database_instance_assignment.node
    @node_database_instance_assignment.destroy

    respond_to do |format|
      format.html { redirect_to node_database_instance_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'node_database_instance_assignments', {:partial => 'nodes/database_instance_assignments', :locals => { :node => @node} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_database_instance_assignments/1;version_history
  def version_history
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
