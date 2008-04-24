require File.dirname(__FILE__) + '/../test_helper'
require 'datacenter_environment_assignments_controller'

# Re-raise errors caught by the controller.
class DatacenterEnvironmentAssignmentsController; def rescue_action(e) raise e end; end

class DatacenterEnvironmentAssignmentsControllerTest < Test::Unit::TestCase
  fixtures :datacenter_environment_assignments

  def setup
    @controller = DatacenterEnvironmentAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:datacenter_environment_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_datacenter_environment_assignment
    old_count = DatacenterEnvironmentAssignment.count
    post :create, :datacenter_environment_assignment => { }
    assert_equal old_count+1, DatacenterEnvironmentAssignment.count
    
    assert_redirected_to datacenter_environment_assignment_path(assigns(:datacenter_environment_assignment))
  end

  def test_should_show_datacenter_environment_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_datacenter_environment_assignment
    put :update, :id => 1, :datacenter_environment_assignment => { }
    assert_redirected_to datacenter_environment_assignment_path(assigns(:datacenter_environment_assignment))
  end
  
  def test_should_destroy_datacenter_environment_assignment
    old_count = DatacenterEnvironmentAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DatacenterEnvironmentAssignment.count
    
    assert_redirected_to datacenter_environment_assignments_path
  end
end
