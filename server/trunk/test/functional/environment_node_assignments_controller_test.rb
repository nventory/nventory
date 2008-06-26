require File.dirname(__FILE__) + '/../test_helper'
require 'environment_node_assignments_controller'

# Re-raise errors caught by the controller.
class EnvironmentNodeAssignmentsController; def rescue_action(e) raise e end; end

class EnvironmentNodeAssignmentsControllerTest < Test::Unit::TestCase
  fixtures :environment_node_assignments

  def setup
    @controller = EnvironmentNodeAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:environment_node_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_environment_node_assignment
    old_count = EnvironmentNodeAssignment.count
    post :create, :environment_node_assignment => { }
    assert_equal old_count+1, EnvironmentNodeAssignment.count
    
    assert_redirected_to environment_node_assignment_path(assigns(:environment_node_assignment))
  end

  def test_should_show_environment_node_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_environment_node_assignment
    put :update, :id => 1, :environment_node_assignment => { }
    assert_redirected_to environment_node_assignment_path(assigns(:environment_node_assignment))
  end
  
  def test_should_destroy_environment_node_assignment
    old_count = EnvironmentNodeAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, EnvironmentNodeAssignment.count
    
    assert_redirected_to environment_node_assignments_path
  end
end
