class LoginController < ApplicationController
  
  def index
    redirect_to :action => "login"
  end
  
  def login
    session[:account_id] = nil
    if request.post? 
      account = Account.authenticate(params[:login], params[:password])
      if account 
        session[:account_id] = account.id
        uri = session[:original_uri] 
        session[:original_uri] = nil 
        redirect_to(uri || { :controller => 'dashboard' })
      else 
        flash[:error] = "Invalid login/password combination"
        session[:account_id] = nil
        redirect_to :controller => 'login', :action => 'login'
      end
    end 
  end
  
  def logout
    session[:account_id] = nil 
    flash[:notice] = "Logged out" 
    redirect_to(:action => "login")
  end
  
end
