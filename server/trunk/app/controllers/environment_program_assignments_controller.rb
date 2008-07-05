class EnvironmentProgramAssignmentsController < ApplicationController
  # GET /environment_program_assignments
  # GET /environment_program_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "environment_program_assignments.assigned_at"
           when "assigned_at_reverse" then "environment_program_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = EnvironmentProgramAssignment.default_search_attribute
      sort = 'environment_program_assignments.' + EnvironmentProgramAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = EnvironmentProgramAssignment.find(:all, :order => sort)
    else
      @objects = EnvironmentProgramAssignment.paginate(:all,
                                                       :order => sort,
                                                       :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /environment_program_assignments/1
  # GET /environment_program_assignments/1.xml
  def show
    @environment_program_assignment = EnvironmentProgramAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @environment_program_assignment.to_xml(:dasherize => false) }
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
        format.xml  { render :xml => @environment_program_assignment.errors.to_xml, :status => :unprocessable_entity }
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
        format.xml  { render :xml => @environment_program_assignment.errors.to_xml, :status => :unprocessable_entity }
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
