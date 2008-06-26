class EnvironmentNodeAssignmentsController < ApplicationController
  # GET /environment_node_assignments
  # GET /environment_node_assignments.xml
  def index
    sort = case @params['sort']
           when "assigned_at" then "environment_node_assignments.assigned_at"
           when "assigned_at_reverse" then "environment_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "assigned_at"
      sort = "environment_node_assignments.assigned_at"
    end
    
    @objects_pages = Paginator.new self, EnvironmentNodeAssignment.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = EnvironmentNodeAssignment.find_by_sql(["SELECT environment_node_assignments.* FROM environment_node_assignments " + 
                              " WHERE environment_node_assignments.deleted_at IS NULL " +
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

  # GET /environment_node_assignments/1
  # GET /environment_node_assignments/1.xml
  def show
    @environment_node_assignment = EnvironmentNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @environment_node_assignment.to_xml }
    end
  end

  # GET /environment_node_assignments/new
  def new
    @environment_node_assignment = EnvironmentNodeAssignment.new
  end

  # GET /environment_node_assignments/1;edit
  def edit
    @environment_node_assignment = EnvironmentNodeAssignment.find(params[:id])
  end

  # POST /environment_node_assignments
  # POST /environment_node_assignments.xml
  def create
    @environment_node_assignment = EnvironmentNodeAssignment.new(params[:environment_node_assignment])

    respond_to do |format|
      if @environment_node_assignment.save
        format.html { 
          flash[:notice] = 'Environment Node Assignment was successfully created.'
          redirect_to environment_node_assignment_url(@environment_node_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'environment_node_assignments', :partial => 'environments/node_assignments', :locals => { :environment => @environment_node_assignment.environment }
            page.hide 'create_node_assignment'
            page.show 'add_node_assignment_link'
          }
        }
        format.xml  { head :created, :location => environment_node_assignment_url(@environment_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@environment_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @environment_node_assignment.errors.to_xml }
      end
    end
  end

  # PUT /environment_node_assignments/1
  # PUT /environment_node_assignments/1.xml
  def update
    @environment_node_assignment = EnvironmentNodeAssignment.find(params[:id])
    
    
    respond_to do |format|
      if @environment_node_assignment.update_attributes(params[:environment_node_assignment])
        flash[:notice] = 'EnvironmentNodeAssignment was successfully updated.'
        format.html { redirect_to environment_node_assignment_url(@environment_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @environment_node_assignment.errors.to_xml }
      end
    end
  end

  # DELETE /environment_node_assignments/1
  # DELETE /environment_node_assignments/1.xml
  def destroy
    @environment_node_assignment = EnvironmentNodeAssignment.find(params[:id])
    @environment = @environment_node_assignment.environment
    @environment_node_assignment.destroy

    respond_to do |format|
      format.html { redirect_to environment_node_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'environment_node_assignments', {:partial => 'environments/node_assignments', :locals => { :environment => @environment} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /environment_node_assignments/1;version_history
  def version_history
    @environment_node_assignment = EnvironmentNodeAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
