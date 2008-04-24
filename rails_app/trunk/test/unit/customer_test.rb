require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < Test::Unit::TestCase
  fixtures :customers

  def test_cant_delete_with_programs
    customer = Customer.create(:name => 'gus')
    status = Status.create(:name => "Joke", :relevant_model => "Program")
    program = Program.create(:name => 'voodoopad', :customer => customer, :status => status)
    
    assert_equal(0, customer.errors.count)
    assert_equal(0, status.errors.count)
    assert_equal(0, program.errors.count)
    assert_equal(1, customer.programs.count) 

    # Test that we can't destroy
    begin
      customer.destroy
    rescue Exception => destroy_error
      assert_equal(destroy_error.message, 'A customer can not be destroyed that has programs assigned to it.')
    else
      flunk('Trouble. We deleted a customer that had a program assigned to it.')
    end
    
    # Remove the program and now try to remove customer
    customer_id = customer.id
    program_id = program.id
    program.destroy
    customer.destroy
    assert(!Customer.exists?(customer_id))
    assert(!Program.exists?(program_id))
  end
  
end
