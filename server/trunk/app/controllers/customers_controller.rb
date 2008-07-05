class CustomersController < ApplicationController
  # GET /customers
  # GET /customers.xml
  def index
    sort = case params['sort']
           when "name" then "customers.name"
           when "name_reverse" then "customers.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Customer.default_search_attribute
      sort = 'customers.' + Customer.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Customer.find(:all, :order => sort)
    else
      @objects = Customer.paginate(:all,
                                   :order => sort,
                                   :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /customers/1
  # GET /customers/1.xml
  def show
    @customer = Customer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @customer.to_xml(:dasherize => false) }
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
        format.xml  { render :xml => @customer.errors.to_xml, :status => :unprocessable_entity }
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
        format.xml  { render :xml => @customer.errors.to_xml, :status => :unprocessable_entity }
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
