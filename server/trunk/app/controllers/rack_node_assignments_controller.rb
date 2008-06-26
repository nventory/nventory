class RackNodeAssignmentsController < ApplicationController
  # GET /rack_node_assignments
  # GET /rack_node_assignments.xml
  def index
    sort = case @params['sort']
           when "assigned_at" then "rack_node_assignments.assigned_at"
           when "assigned_at_reverse" then "rack_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "assigned_at"
      sort = "rack_node_assignments.assigned_at"
    end
    
    @objects_pages = Paginator.new self, RackNodeAssignment.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = RackNodeAssignment.find_by_sql(["SELECT rack_node_assignments.* FROM rack_node_assignments " + 
                              " WHERE rack_node_assignments.deleted_at IS NULL " +
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

  # GET /rack_node_assignments/1
  # GET /rack_node_assignments/1.xml
  def show
    @rack_node_assignment = RackNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @rack_node_assignment.to_xml }
    end
  end

  # GET /rack_node_assignments/new
  def new
    @rack_node_assignment = RackNodeAssignment.new
  end

  # GET /rack_node_assignments/1;edit
  def edit
    @rack_node_assignment = RackNodeAssignment.find(params[:id])
  end

  # POST /rack_node_assignments
  # POST /rack_node_assignments.xml
  def create
    @rack_node_assignment = RackNodeAssignment.new(params[:rack_node_assignment])

    respond_to do |format|
      if @rack_node_assignment.save
        format.html {
          flash[:notice] = 'RackNodeAssignment was successfully created.'
          redirect_to rack_node_assignment_url(@rack_node_assignment)
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'rack_node_assignments', :partial => 'racks/node_assignments', :locals => { :rack => @rack_node_assignment.rack }
            page.hide 'create_node_assignment'
            page.show 'add_node_assignment_link'
          }
        }
        format.xml  { head :created, :location => rack_node_assignment_url(@rack_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@rack_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @rack_node_assignment.errors.to_xml }
      end
    end
  end

  # PUT /rack_node_assignments/1
  # PUT /rack_node_assignments/1.xml
  def update
    @rack_node_assignment = RackNodeAssignment.find(params[:id])

    respond_to do |format|
      if @rack_node_assignment.update_attributes(params[:rack_node_assignment])
        flash[:notice] = 'RackNodeAssignment was successfully updated.'
        format.html { redirect_to rack_node_assignment_url(@rack_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rack_node_assignment.errors.to_xml }
      end
    end
  end

  # DELETE /rack_node_assignments/1
  # DELETE /rack_node_assignments/1.xml
  def destroy
    @rack_node_assignment = RackNodeAssignment.find(params[:id])
    @rack = @rack_node_assignment.rack
    @rack_node_assignment.destroy

    respond_to do |format|
      format.html { redirect_to rack_node_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'rack_node_assignments', {:partial => 'racks/node_assignments', :locals => { :rack => @rack} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /rack_node_assignments/1;version_history
  def version_history
    @rack_node_assignment = RackNodeAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
