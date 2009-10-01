class ServiceServiceAssignmentsController < ApplicationController
  # GET /service_service_assignments
  # GET /service_service_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "service_service_assignments.assigned_at"
           when "assigned_at_reverse" then "service_service_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = ServiceServiceAssignment.default_search_attribute
      sort = 'service_service_assignments.' + ServiceServiceAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = ServiceServiceAssignment.find(:all, :order => sort)
    else
      @objects = ServiceServiceAssignment.paginate(:all,
                                                   :order => sort,
                                                   :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /service_service_assignments/1
  # GET /service_service_assignments/1.xml
  def show
    @service_service_assignment = ServiceServiceAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_service_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /service_service_assignments/new
  def new
    @service_service_assignment = ServiceServiceAssignment.new
  end

  # GET /service_service_assignments/1/edit
  def edit
    @service_service_assignment = ServiceServiceAssignment.find(params[:id])
  end

  # POST /service_service_assignments
  # POST /service_service_assignments.xml
  def create
    @service_service_assignment = ServiceServiceAssignment.new(params[:service_service_assignment])

    respond_to do |format|
      if @service_service_assignment.save
        
        format.html { 
          flash[:notice] = 'ServiceServiceAssignment was successfully created.'
          redirect_to service_service_assignment_url(@service_service_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            
            page.replace_html 'service_service_assignments', :partial => 'nodes/service_service_assignments', :locals => { :node => @service_service_assignment.node }
            page.hide 'create_service_service_assignment'
            page.show 'add_service_service_assignment_link'
          }
        }
        format.xml  { head :created, :location => service_service_assignment_url(@service_service_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@service_service_assignment.errors.full_messages) } }
        format.xml  { render :xml => @service_service_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_service_assignments/1
  # PUT /service_service_assignments/1.xml
  def update
    @service_service_assignment = ServiceServiceAssignment.find(params[:id])

    respond_to do |format|
      if @service_service_assignment.update_attributes(params[:service_service_assignment])
        flash[:notice] = 'ServiceServiceAssignment was successfully updated.'
        format.html { redirect_to service_service_assignment_url(@service_service_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_service_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_service_assignments/1
  # DELETE /service_service_assignments/1.xml
  def destroy
    @service_service_assignment = ServiceServiceAssignment.find(params[:id])
    @parent_service = @service_service_assignment.parent_service
    @child_service = @service_service_assignment.child_service
    
    begin
      @service_service_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to service_service_assignment_url(@service_service_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to service_service_assignments_url }
      format.js {
        render(:update) { |page|
          
          page.replace_html 'service_service_assignments', {:partial => 'nodes/service_service_assignments', :locals => { :node => @node} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /service_service_assignments/1/version_history
  def version_history
    @service_service_assignment = ServiceServiceAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
