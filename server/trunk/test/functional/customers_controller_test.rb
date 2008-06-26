require File.dirname(__FILE__) + '/../test_helper'
require 'customers_controller'

# Re-raise errors caught by the controller.
class CustomersController; def rescue_action(e) raise e end; end

class CustomersControllerTest < Test::Unit::TestCase
  fixtures :customers

  def setup
    @controller = CustomersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:customers)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_customer
    old_count = Customer.count
    post :create, :customer => { }
    assert_equal old_count+1, Customer.count
    
    assert_redirected_to customer_path(assigns(:customer))
  end

  def test_should_show_customer
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_customer
    put :update, :id => 1, :customer => { }
    assert_redirected_to customer_path(assigns(:customer))
  end
  
  def test_should_destroy_customer
    old_count = Customer.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Customer.count
    
    assert_redirected_to customers_path
  end
end
