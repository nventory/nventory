class EnvironmentProgramAssignmentsController < ApplicationController
  # GET /environment_program_assignments
  # GET /environment_program_assignments.xml
  def index
    sort = case @params['sort']
           when "assigned_at" then "environment_program_assignments.assigned_at"
           when "assigned_at_reverse" then "environment_program_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "assigned_at"
      sort = "environment_program_assignments.assigned_at"
    end
    
    @objects_pages = Paginator.new self, EnvironmentProgramAssignment.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = EnvironmentProgramAssignment.find_by_sql(["SELECT environment_program_assignments.* FROM environment_program_assignments " + 
                              " WHERE environment_program_assignments.deleted_at IS NULL " +
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

  # GET /environment_program_assignments/1
  # GET /environment_program_assignments/1.xml
  def show
    @environment_program_assignment = EnvironmentProgramAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @environment_program_assignment.to_xml }
    end
  end

  # GET /environment_program_assignments/new
  def new
    @environment_program_assignment = EnvironmentProgramAssignment.new
  end

  # GET /environment_program_assignments/1;edit
  def edit
    @environment_program_assignment = EnvironmentProgramAssignment.find(params[:id])
  end

  # POST /environment_program_assignments
  # POST /environment_program_assignments.xml
  def create
    @environment_program_assignment = EnvironmentProgramAssignment.new(params[:environment_program_assignment])

    respond_to do |format|
      if @environment_program_assignment.save
        format.html { 
          flash[:notice] = 'Environment Program Assignment was successfully created.'
          redirect_to environment_program_assignment_url(@environment_program_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'environment_program_assignments', :partial => 'environments/program_assignments', :locals => { :environment => @environment_program_assignment.environment }
            page.hide 'create_program_assignment'
            page.show 'add_program_assignment_link'
          }
        }
        format.xml  { head :created, :location => environment_program_assignment_url(@environment_program_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@environment_program_assignment.errors.full_messages) } }
        format.xml  { render :xml => @environment_program_assignment.errors.to_xml }
      end
    end
  end

  # PUT /environment_program_assignments/1
  # PUT /environment_program_assignments/1.xml
  def update
    @environment_program_assignment = EnvironmentProgramAssignment.find(params[:id])

    respond_to do |format|
      if @environment_program_assignment.update_attributes(params[:environment_program_assignment])
        flash[:notice] = 'EnvironmentProgramAssignment was successfully updated.'
        format.html { redirect_to environment_program_assignment_url(@environment_program_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @environment_program_assignment.errors.to_xml }
      end
    end
  end

  # DELETE /environment_program_assignments/1
  # DELETE /environment_program_assignments/1.xml
  def destroy
    @environment_program_assignment = EnvironmentProgramAssignment.find(params[:id])
    @environment = @environment_program_assignment.environment
    @environment_program_assignment.destroy

    respond_to do |format|
      format.html { redirect_to environment_program_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'environment_program_assignments', {:partial => 'environments/program_assignments', :locals => { :environment => @environment} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /environment_program_assignments/1;version_history
  def version_history
    @environment_program_assignment = EnvironmentProgramAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  
end
