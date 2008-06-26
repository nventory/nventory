class NodesController < ApplicationController
  # GET /nodes
  # GET /nodes.xml
  def index
    
    sort = case @params['sort']
           when "name" then "nodes.name"
           when "name_reverse" then "nodes.name DESC"
           when "serial_number" then "nodes.serial_number"
           when "serial_number_reverse" then "nodes.serial_number DESC"
           when "status" then "statuses.name"
           when "status_reverse" then "statuses.name DESC"
           when "hardware_profile" then "hardware_profiles.name"
           when "hardware_profile_reverse" then "hardware_profiles.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "nodes.name"
    end
    
    # build incoming searchquery hash based on namespace
    searchquery = Hash.new
    @params.each_pair do |key, value|
      if key.include? "searchquery_"
        searchquery[key[12..key.length]] = value
      end
    end
    
    logger.info "searchquery" + searchquery.to_yaml
    
    # Look to see if they are searching
    search_conditions = Hash.new
    if !searchquery.empty?
      search_conditions[:customer] = searchquery['customer'] unless searchquery['customer'].blank?
      search_conditions[:function] = searchquery['function'] unless searchquery['function'].blank?
      search_conditions[:hardware_profile] = searchquery['hardware_profile'] unless searchquery['hardware_profile'].blank?
      search_conditions[:status] = searchquery['status'] unless searchquery['status'].blank?
    end
    
    sql_select = "SELECT DISTINCT nodes.*"
    sql_select_count = "SELECT COUNT(DISTINCT nodes.id)"
    sql_from = " FROM nodes, statuses, hardware_profiles"
    sql_where = " WHERE nodes.status_id = statuses.id AND nodes.hardware_profile_id = hardware_profiles.id AND nodes.deleted_at IS NULL "
    
    if search_conditions.has_key?(:status)
      sql_where = sql_where + " AND statuses.name = :status"
    end
    
    if search_conditions.has_key?(:hardware_profile)
      sql_where = sql_where + " AND hardware_profiles.name = :hardware_profile"
    end
    
    if search_conditions.has_key?(:function)
      sql_from = sql_from + ", node_function_assignments, functions"
      sql_where = sql_where + " AND node_function_assignments.node_id = nodes.id AND node_function_assignments.function_id = functions.id"
      sql_where = sql_where + " AND functions.name = :function"
    end
    
    if search_conditions.has_key?(:customer)
      sql_from = sql_from + ", environment_node_assignments, environments, environment_program_assignments, programs, customers"
      sql_where = sql_where + " AND environment_node_assignments.node_id = nodes.id AND environment_node_assignments.environment_id = environments.id AND environment_program_assignments.environment_id = environments.id AND environment_program_assignments.program_id = programs.id AND programs.customer_id = customers.id"
      sql_where = sql_where + " AND customers.name = :customer"
    end
    
    sql_count = sql_select_count + sql_from + sql_where
    
    @total_found = Node.count_by_sql([sql_count, search_conditions])
    
    @objects_pages = Paginator.new self, @total_found, DEFAULT_SEARCH_RESULT_COUNT, params[:page]

    sql_order  = " ORDER BY #{sort} LIMIT :offset,:per_page_count "
    
    sql_string = sql_select + sql_from + sql_where + sql_order
    
    sql_hash = {
      :offset => @objects_pages.current.offset,
      :per_page_count => @objects_pages.items_per_page
    }
    
    # add the items found in search to the substitution hash (they might be asked for)
    sql_hash.merge!(search_conditions)
    
    @objects = Node.find_by_sql([sql_string, sql_hash])
    
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

  # GET /nodes/1
  # GET /nodes/1.xml
  def show
    @node = Node.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @node.to_xml }
    end
  end

  # GET /nodes/new
  def new
    @node = Node.new
    respond_to do |format|
      format.html # show.rhtml
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /nodes/1;edit
  def edit
    @node = Node.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.xml
  def create
    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        flash[:notice] = 'Node was successfully created.'
        format.html { redirect_to node_url(@node) }
        format.js { 
          render(:update) { |page| 
            
            # we expect this ajax creation to come from one of two places, the rack show page or the enviornment show page. Depending on which
            # we do something slightly different.
            if request.env["HTTP_REFERER"].include? "racks"
              page.replace_html 'create_node_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'rack', :to => 'node' }
              page['rack_node_assignment_node_id'].value = @node.id
            elsif request.env["HTTP_REFERER"].include? "environments"
              page.replace_html 'create_node_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'environment', :to => 'node' }
              page['environment_node_assignment_node_id'].value = @node.id
            end
            
            page.hide 'new_node'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_node_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
          }
        }
        format.xml  { head :created, :location => node_url(@node) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node.errors.full_messages) } }
        format.xml  { render :xml => @node.errors.to_xml }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.xml
  def update
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        flash[:notice] = 'Node was successfully updated.'
        format.html { redirect_to node_url(@node) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node.errors.to_xml }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.xml
  def destroy
    @node = Node.find(params[:id])
    begin
      @node.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to node_url(@node) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to nodes_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /nodes/1;version_history
  def version_history
    @node = Node.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /nodes/1;available_outlet_consumers
  def available_outlet_consumers
    # @node = Node.find(params[:id])
    @nodes = Node.find(:all, :order => 'name')
    render :action => "available_outlet_consumers", :layout => false
  end
  
end
