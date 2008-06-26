class AccountsController < ApplicationController
  # GET /accounts
  # GET /accounts.xml
  def index
    sort = case @params['sort']
           when "login" then "accounts.login"
           when "login_reverse" then "accounts.login DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      @params['sort'] = "login"
      sort = "accounts.login"
    end
    
    @objects_pages = Paginator.new self, Account.count(), DEFAULT_SEARCH_RESULT_COUNT, params[:page]
    @objects = Account.find_by_sql(["SELECT accounts.* FROM accounts " + 
                              " WHERE accounts.deleted_at IS NULL " +
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

  # GET /accounts/1
  # GET /accounts/1.xml
  def show
    @account = Account.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @account.to_xml }
    end
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1;edit
  def edit
    @account = Account.find(params[:id])
  end

  # POST /accounts
  # POST /accounts.xml
  def create
    @account = Account.new(params[:account])

    respond_to do |format|
      if @account.save
        flash[:notice] = 'Account was successfully created.'
        format.html { redirect_to account_url(@account) }
        format.xml  { head :created, :location => account_url(@account) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @account.errors.to_xml }
      end
    end
  end

  # PUT /accounts/1
  # PUT /accounts/1.xml
  def update
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        flash[:notice] = 'Account was successfully updated.'
        format.html { redirect_to account_url(@account) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account.errors.to_xml }
      end
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.xml
  def destroy
    @account = Account.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to accounts_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /customers/1;version_history
  def version_history
    @account = Account.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
