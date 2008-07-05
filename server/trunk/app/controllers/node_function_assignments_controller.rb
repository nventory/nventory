class NodeFunctionAssignmentsController < ApplicationController
  # GET /node_function_assignments
  # GET /node_function_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "node_function_assignments.assigned_at"
           when "assigned_at_reverse" then "node_function_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NodeFunctionAssignment.default_search_attribute
      sort = 'node_function_assignments.' + NodeFunctionAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = NodeFunctionAssignment.find(:all, :order => sort)
    else
      @objects = NodeFunctionAssignment.paginate(:all,
                                                 :order => sort,
                                                 :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /node_function_assignments/1
  # GET /node_function_assignments/1.xml
  def show
    @node_function_assignment = NodeFunctionAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_function_assignment.to_xml(:dasherize => false) }
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
        format.xml  { render :xml => @node_function_assignment.errors.to_xml, :status => :unprocessable_entity }
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
        format.xml  { render :xml => @node_function_assignment.errors.to_xml, :status => :unprocessable_entity }
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
