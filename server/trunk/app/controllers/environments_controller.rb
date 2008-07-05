class EnvironmentsController < ApplicationController
  # GET /environments
  # GET /environments.xml
  def index
    sort = case params['sort']
           when "name" then "environments.name"
           when "name_reverse" then "environments.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Environment.default_search_attribute
      sort = 'environments.' + Environment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Environment.find(:all, :order => sort)
    else
      @objects = Environment.paginate(:all,
                                      :order => sort,
                                      :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /environments/1
  # GET /environments/1.xml
  def show
    @environment = Environment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :action => "xml_configuration", :layout => false }
    end
  end

  # GET /environments/new
  def new
    @environment = Environment.new
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /environments/1;edit
  def edit
    @environment = Environment.find(params[:id])
  end
  
  # GET /environments/1;xml_configuration
  def xml_configuration
    @environment = Environment.find(params[:id])
    render :layout => false
  end

  # POST /environments
  # POST /environments.xml
  def create
    @environment = Environment.new(params[:environment])

    respond_to do |format|
      if @environment.save
        flash[:notice] = 'Environment was successfully created.'
        format.html { redirect_to environment_url(@environment) }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_environment_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'datacenter', :to => 'environment' }
            page['datacenter_environment_assignment_environment_id'].value = @environment.id
            page.hide 'new_environment'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_environment_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
            
          }
        }
        format.xml  { head :created, :location => environment_url(@environment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@environment.errors.full_messages) } }
        format.xml  { render :xml => @environment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /environments/1
  # PUT /environments/1.xml
  def update
    @environment = Environment.find(params[:id])

    respond_to do |format|
      if @environment.update_attributes(params[:environment])
        flash[:notice] = 'Environment was successfully updated.'
        format.html { redirect_to environment_url(@environment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @environment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /environments/1
  # DELETE /environments/1.xml
  def destroy
    @environment = Environment.find(params[:id])
    @environment.destroy

    respond_to do |format|
      format.html { redirect_to environments_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /environments/1;version_history
  def version_history
    @environment = Environment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
