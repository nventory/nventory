class CustomersController < ApplicationController
  # GET /customers
  # GET /customers.xml
  def index
    sort = case @params['sort']
           when "name" then "customers.name"
           when "name_reverse" then "customers.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "name"
      sort = "customers.name"
    end
    
    @objects_pages = Paginator.new self, Customer.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = Customer.find_by_sql(["SELECT customers.* FROM customers " + 
                              " WHERE customers.deleted_at IS NULL " +
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

  # GET /customers/1
  # GET /customers/1.xml
  def show
    @customer = Customer.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @customer.to_xml }
    end
  end

  # GET /customers/new
  def new
    @customer = Customer.new
  end

  # GET /customers/1;edit
  def edit
    @customer = Customer.find(params[:id])
  end

  # POST /customers
  # POST /customers.xml
  def create
    @customer = Customer.new(params[:customer])

    respond_to do |format|
      if @customer.save
        flash[:notice] = 'Customer was successfully created.'
        format.html { redirect_to customer_url(@customer) }
        format.xml  { head :created, :location => customer_url(@customer) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @customer.errors.to_xml }
      end
    end
  end

  # PUT /customers/1
  # PUT /customers/1.xml
  def update
    @customer = Customer.find(params[:id])

    respond_to do |format|
      if @customer.update_attributes(params[:customer])
        flash[:notice] = 'Customer was successfully updated.'
        format.html { redirect_to customer_url(@customer) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @customer.errors.to_xml }
      end
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.xml
  def destroy
    @customer = Customer.find(params[:id])
    begin
      @customer.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to customer_url(@customer) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to customers_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /customers/1;version_history
  def version_history
    @customer = Customer.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
