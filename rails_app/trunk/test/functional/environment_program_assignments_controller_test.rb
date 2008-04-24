require File.dirname(__FILE__) + '/../test_helper'
require 'environment_program_assignments_controller'

# Re-raise errors caught by the controller.
class EnvironmentProgramAssignmentsController; def rescue_action(e) raise e end; end

class EnvironmentProgramAssignmentsControllerTest < Test::Unit::TestCase
  fixtures :environment_program_assignments

  def setup
    @controller = EnvironmentProgramAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:environment_program_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_environment_program_assignment
    old_count = EnvironmentProgramAssignment.count
    post :create, :environment_program_assignment => { }
    assert_equal old_count+1, EnvironmentProgramAssignment.count
    
    assert_redirected_to environment_program_assignment_path(assigns(:environment_program_assignment))
  end

  def test_should_show_environment_program_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_environment_program_assignment
    put :update, :id => 1, :environment_program_assignment => { }
    assert_redirected_to environment_program_assignment_path(assigns(:environment_program_assignment))
  end
  
  def test_should_destroy_environment_program_assignment
    old_count = EnvironmentProgramAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, EnvironmentProgramAssignment.count
    
    assert_redirected_to environment_program_assignments_path
  end
end
