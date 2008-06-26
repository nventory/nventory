require File.dirname(__FILE__) + '/../test_helper'
require 'function_types_controller'

# Re-raise errors caught by the controller.
class FunctionTypesController; def rescue_action(e) raise e end; end

class FunctionTypesControllerTest < Test::Unit::TestCase
  fixtures :function_types

  def setup
    @controller = FunctionTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:function_types)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_function_type
    old_count = FunctionType.count
    post :create, :function_type => { }
    assert_equal old_count+1, FunctionType.count
    
    assert_redirected_to function_type_path(assigns(:function_type))
  end

  def test_should_show_function_type
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_function_type
    put :update, :id => 1, :function_type => { }
    assert_redirected_to function_type_path(assigns(:function_type))
  end
  
  def test_should_destroy_function_type
    old_count = FunctionType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, FunctionType.count
    
    assert_redirected_to function_types_path
  end
end
