require File.dirname(__FILE__) + '/../test_helper'

class FunctionTest < Test::Unit::TestCase
  fixtures :functions

  def test_cant_delete_with_node_assignment
    function = Function.create(:name => 'function-01', :function_type => FunctionType.find(:all, :order => 'name').first)
    node = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    node_function_assignment = NodeFunctionAssignment.create(:node => node, :function => function)
    
    assert_equal(0, function.errors.count)
    assert_equal(0, node.errors.count)
    assert_equal(0, node_function_assignment.errors.count)
    assert_equal(1, node.node_function_assignments.count) 
    assert_equal(1, node.functions.count) 
    
    # Test that we can't destroy
    begin
      function.destroy
    rescue Exception => destroy_error
      assert_equal(destroy_error.message, 'A function can not be destroyed that has nodes assigned to it.')
    else
      flunk('Trouble. We deleted a function that had a node assigned to it.')
    end
    
    # Remove the assignment, and make sure bob was destroyed
    node_function_assignment_id = node_function_assignment.id
    node_id = node.id
    function_id = function.id
    node_function_assignment.destroy
    function.destroy
    assert(!Function.exists?(function_id))
    assert(Node.exists?(node_id)) # the node lives!
    assert(!NodeFunctionAssignment.exists?(node_function_assignment_id))
  end
  
end
