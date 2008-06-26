# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_nventory_session_id'
  
  before_filter :check_authentication, :except => :login
  
  def check_authentication 
    unless session[:account_id] 
      session[:original_uri] = request.request_uri
      flash[:error] = "Please authenticate to access that page."
      redirect_to :controller => "login", :action => "login" 
    end 
  end
  
end
