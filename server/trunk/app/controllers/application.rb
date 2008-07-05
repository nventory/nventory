# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # GET requests with no user agent are probably monitoring agents of some
  # sort (including load balancer health checks) and creating sessions for
  # them just fills up the session table with junk
  session :off, :if => Proc.new { |request| request.env['HTTP_USER_AGENT'].blank? && request.get? }

  # Turn on the exception_notification plugin
  # See environment.rb for the email address(s) to which exceptions are mailed
  include ExceptionNotifiable

  # Turn on the ssl_requirement plugin
  # The login controller uses it to ensure that authentication occurs
  # over SSL.  All other activity that comes in on the SSL side (https)
  # will be redirected to the non-SSL (http) side.
  include SslRequirement

  # Turn on the acts_as_audited plugin for appropriate models
  audit Account, Customer, DatabaseInstance, DatabaseInstanceRelationship,
    Datacenter, DatacenterEnvironmentAssignment, DatacenterRackAssignment,
    DatacenterVipAssignment, Environment, EnvironmentNodeAssignment,
    EnvironmentProgramAssignment, Function, FunctionType, HardwareProfile,
    IpAddress, NetworkInterface, Node, NodeDatabaseInstanceAssignment,
    NodeFunctionAssignment, NodeGroup, NodeGroupNodeAssignment,
    NodeGroupNodeGroupAssignment, OperatingSystem, Outlet, Program, Rack,
    RackNodeAssignment, Status, Subnet, Vip

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_nventory_session_id'
  
  before_filter :check_authentication, :except => :login
  before_filter :check_authorization, :except => :login
  # Don't log passwords
  filter_parameter_logging "password"
  
  def check_authentication 
    # Always require web UI users to authenticate, so that they're
    # already authenticated if they want to make a change.  This
    # provides for a more seamless user experience.  XML users
    # don't have to authenticate unless they're making a change.
    if params[:format] && params[:format] == 'xml'
      return true if request.get?
    end

    unless session[:account_id] 
      session[:original_uri] = request.request_uri
      flash[:error] = "Please authenticate to access that page."
      redirect_to :controller => "login", :action => "login"
      return false
    end 

    # Give the thumb's up if we didn't find any reason to reject the user
    return true
  end

  def check_authorization
    if !request.get?
      acct = Account.find(session[:account_id])
      if acct.nil? || !acct.admin
        logger.info "Rejecting user for lack of admin privs"
        if params[:format] && params[:format] == 'xml'
          # Seems like there ought to be a slightly easier way to do this
          errs = ''
          xm = Builder::XmlMarkup.new(:target => errs, :indent => 2)
          xm.instruct!
          xm.errors{ xm.error('You must have admin privileges to make changes') }
          render :xml => errs, :status => :unauthorized
          return false
        else
          flash[:error] = 'You must have admin privileges to make changes'
          begin
            redirect_to :back
          # The rescue syntax here seems odd, but it works
          # http://www.ruby-forum.com/topic/85701
          rescue ::ActionController::RedirectBackError
            # This seems like a reasonable default destination in this case
            redirect_to :controller => "login", :action => "login"
          end
          return false
        end
      end
    end
    # Give the thumb's up if we didn't find any reason to reject the user
    return true
  end
  
  # Used by acts_as_audited
  protected
    def current_user
      @user ||= Account.find(session[:account_id]) if session[:account_id]
    end

end
