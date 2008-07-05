class ProgramsController < ApplicationController
  # GET /programs
  # GET /programs.xml
  def index
    sort = case params['sort']
           when "name" then "programs.name"
           when "name_reverse" then "programs.name DESC"
           when "customer" then "customers.name"
           when "customer_reverse" then "customers.name DESC"
           when "status" then "statuses.name"
           when "status_reverse" then "statuses.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Program.default_search_attribute
      sort = 'programs.' + Program.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Program.find(:all,
                              :include => [ :status, :customer ],
                              :order => sort)
    else
      @objects = Program.paginate(:all,
                                  :include => [ :status, :customer ],
                                  :order => sort,
                                  :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /programs/1
  # GET /programs/1.xml
  def show
    @program = Program.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @program.to_xml(:dasherize => false) }
    end
  end

  # GET /programs/new
  def new
    @program = Program.new
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /programs/1;edit
  def edit
    @program = Program.find(params[:id])
  end

  # POST /programs
  # POST /programs.xml
  def create
    @program = Program.new(params[:program])

    respond_to do |format|
      if @program.save
        format.html { 
          flash[:notice] = 'Program was successfully created.'
          redirect_to program_url(@program) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_program_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'environment', :to => 'program' }
            page['environment_program_assignment_program_id'].value = @program.id
            page.hide 'new_program'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_program_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
            
          }
        }
        format.xml  { head :created, :location => program_url(@program) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@program.errors.full_messages) } }
        format.xml  { render :xml => @program.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /programs/1
  # PUT /programs/1.xml
  def update
    @program = Program.find(params[:id])

    respond_to do |format|
      if @program.update_attributes(params[:program])
        flash[:notice] = 'Program was successfully updated.'
        format.html { redirect_to program_url(@program) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @program.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /programs/1
  # DELETE /programs/1.xml
  def destroy
    @program = Program.find(params[:id])
    @program.destroy

    respond_to do |format|
      format.html { redirect_to programs_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /programs/1;version_history
  def version_history
    @program = Program.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
