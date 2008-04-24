require File.dirname(__FILE__) + '/../test_helper'
require 'node_function_assignments_controller'

# Re-raise errors caught by the controller.
class NodeFunctionAssignmentsController; def rescue_action(e) raise e end; end

class NodeFunctionAssignmentsControllerTest < Test::Unit::TestCase
  fixtures :node_function_assignments

  def setup
    @controller = NodeFunctionAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:node_function_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_node_function_assignment
    old_count = NodeFunctionAssignment.count
    post :create, :node_function_assignment => { }
    assert_equal old_count+1, NodeFunctionAssignment.count
    
    assert_redirected_to node_function_assignment_path(assigns(:node_function_assignment))
  end

  def test_should_show_node_function_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_node_function_assignment
    put :update, :id => 1, :node_function_assignment => { }
    assert_redirected_to node_function_assignment_path(assigns(:node_function_assignment))
  end
  
  def test_should_destroy_node_function_assignment
    old_count = NodeFunctionAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, NodeFunctionAssignment.count
    
    assert_redirected_to node_function_assignments_path
  end
end
