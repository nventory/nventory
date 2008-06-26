class DatacenterEnvironmentAssignmentsController < ApplicationController
  # GET /datacenter_environment_assignments
  # GET /datacenter_environment_assignments.xml
  def index
    sort = case @params['sort']
           when "assigned_at" then "datacenter_environment_assignments.assigned_at"
           when "assigned_at_reverse" then "datacenter_environment_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "assigned_at"
      sort = "datacenter_environment_assignments.assigned_at"
    end
    
    @objects_pages = Paginator.new self, DatacenterEnvironmentAssignment.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = DatacenterEnvironmentAssignment.find_by_sql(["SELECT datacenter_environment_assignments.* FROM datacenter_environment_assignments " + 
                              " WHERE datacenter_environment_assignments.deleted_at IS NULL " +
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

  # GET /datacenter_environment_assignments/1
  # GET /datacenter_environment_assignments/1.xml
  def show
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @datacenter_environment_assignment.to_xml }
    end
  end

  # GET /datacenter_environment_assignments/new
  def new
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.new
  end

  # GET /datacenter_environment_assignments/1;edit
  def edit
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.find(params[:id])
  end

  # POST /datacenter_environment_assignments
  # POST /datacenter_environment_assignments.xml
  def create
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.new(params[:datacenter_environment_assignment])

    respond_to do |format|
      if @datacenter_environment_assignment.save
        format.html { 
          flash[:notice] = 'Datacenter Environment Assignment was successfully created.'
          redirect_to datacenter_environment_assignment_url(@datacenter_environment_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'datacenter_environment_assignments', :partial => 'datacenters/environment_assignments', :locals => { :datacenter => @datacenter_environment_assignment.datacenter }
            page.hide 'create_environment_assignment'
            page.show 'add_environment_assignment_link'
          }
        }
        format.xml  { head :created, :location => datacenter_environment_assignment_url(@datacenter_environment_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@datacenter_environment_assignment.errors.full_messages) } }
        format.xml  { render :xml => @datacenter_environment_assignment.errors.to_xml }
      end
    end
  end

  # PUT /datacenter_environment_assignments/1
  # PUT /datacenter_environment_assignments/1.xml
  def update
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.find(params[:id])

    respond_to do |format|
      if @datacenter_environment_assignment.update_attributes(params[:datacenter_environment_assignment])
        flash[:notice] = 'DatacenterEnvironmentAssignment was successfully updated.'
        format.html { redirect_to datacenter_environment_assignment_url(@datacenter_environment_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datacenter_environment_assignment.errors.to_xml }
      end
    end
  end

  # DELETE /datacenter_environment_assignments/1
  # DELETE /datacenter_environment_assignments/1.xml
  def destroy
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.find(params[:id])
    @datacenter = @datacenter_environment_assignment.datacenter
    @datacenter_environment_assignment.destroy

    respond_to do |format|
      format.html { redirect_to datacenter_environment_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'datacenter_environment_assignments', {:partial => 'datacenters/environment_assignments', :locals => { :datacenter => @datacenter} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenter_environment_assignments/1;version_history
  def version_history
    @datacenter_environment_assignment = DatacenterEnvironmentAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
