class NodeFunctionAssignmentsController < ApplicationController
  # GET /node_function_assignments
  # GET /node_function_assignments.xml
  def index
    sort = case @params['sort']
           when "assigned_at" then "node_function_assignments.assigned_at"
           when "assigned_at_reverse" then "node_function_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "assigned_at"
      sort = "node_function_assignments.assigned_at"
    end
    
    @objects_pages = Paginator.new self, NodeFunctionAssignment.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = NodeFunctionAssignment.find_by_sql(["SELECT node_function_assignments.* FROM node_function_assignments " + 
                              " WHERE node_function_assignments.deleted_at IS NULL " +
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

  # GET /node_function_assignments/1
  # GET /node_function_assignments/1.xml
  def show
    @node_function_assignment = NodeFunctionAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @node_function_assignment.to_xml }
    end
  end

  # GET /node_function_assignments/new
  def new
    @node_function_assignment = NodeFunctionAssignment.new
  end

  # GET /node_function_assignments/1;edit
  def edit
    @node_function_assignment = NodeFunctionAssignment.find(params[:id])
  end

  # POST /node_function_assignments
  # POST /node_function_assignments.xml
  def create
    @node_function_assignment = NodeFunctionAssignment.new(params[:node_function_assignment])

    respond_to do |format|
      if @node_function_assignment.save
        
        format.html { 
          flash[:notice] = 'NodeFunctionAssignment was successfully created.'
          redirect_to node_function_assignment_url(@node_function_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            
            # if the function being added will enable the database instance ui then we need to reload the whole page.
            if @node_function_assignment.function.function_type.enables_database_instance_access?
              page.redirect_to node_url(@node_function_assignment.node) 
            else
              page.replace_html 'node_function_assignments', :partial => 'nodes/function_assignments', :locals => { :node => @node_function_assignment.node }
              page.hide 'create_function_assignment'
              page.show 'add_function_assignment_link'
            end
          }
        }
        format.xml  { head :created, :location => node_function_assignment_url(@node_function_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_function_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_function_assignment.errors.to_xml }
      end
    end
  end

  # PUT /node_function_assignments/1
  # PUT /node_function_assignments/1.xml
  def update
    @node_function_assignment = NodeFunctionAssignment.find(params[:id])

    respond_to do |format|
      if @node_function_assignment.update_attributes(params[:node_function_assignment])
        flash[:notice] = 'NodeFunctionAssignment was successfully updated.'
        format.html { redirect_to node_function_assignment_url(@node_function_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_function_assignment.errors.to_xml }
      end
    end
  end

  # DELETE /node_function_assignments/1
  # DELETE /node_function_assignments/1.xml
  def destroy
    @node_function_assignment = NodeFunctionAssignment.find(params[:id])
    @node = @node_function_assignment.node
    @function = @node_function_assignment.function
    
    begin
      @node_function_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to node_function_assignment_url(@node_function_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to node_function_assignments_url }
      format.js {
        render(:update) { |page|
          
          # if the old function enabled database instance access
          if @node_function_assignment.function.function_type.enables_database_instance_access?
            page.redirect_to node_url(@node_function_assignment.node) 
          else
            page.replace_html 'node_function_assignments', {:partial => 'nodes/function_assignments', :locals => { :node => @node} }
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_function_assignments/1;version_history
  def version_history
    @node_function_assignment = NodeFunctionAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
