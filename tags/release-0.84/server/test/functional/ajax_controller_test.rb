require File.dirname(__FILE__) + '/../test_helper'
require 'ajax_controller'

# Re-raise errors caught by the controller.
class AjaxController; def rescue_action(e) raise e end; end

class AjaxControllerTest < Test::Unit::TestCase
  def setup
    @controller = AjaxController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
