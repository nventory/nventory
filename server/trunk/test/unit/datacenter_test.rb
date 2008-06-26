require File.dirname(__FILE__) + '/../test_helper'

class DatacenterTest < Test::Unit::TestCase
  fixtures :datacenters
  
  def test_invalid_with_empty_name
    datacenter = Datacenter.new 
    assert(!datacenter.valid?) 
    assert(datacenter.errors.invalid?(:name))
  end
  
  def test_cant_delete_with_rack_assignment
    bob = Datacenter.create(:name => 'Bob')
    rack1 = Rack.create(:name => 'bob-rack-01')
    bob_rack1_assignment = DatacenterRackAssignment.create(:datacenter => bob, :rack => rack1)
    
    # Test that we can't destroy
    begin
      bob.destroy
    rescue Exception => destroy_error
      assert_equal(destroy_error.message, 'A datacenter can not be destroyed that has racks assigned to it.')
    else
      flunk('Trouble. We deleted a datacenter that had a rack assigned to it.')
    end
    
    # Remove the assignment, and make sure bob was destroyed
    bob_rack1_assignment_id = bob_rack1_assignment.id
    rack1_id = rack1.id
    bob_id = bob.id
    bob_rack1_assignment.destroy
    bob.destroy
    assert(!Datacenter.exists?(bob_id))
    assert(Rack.exists?(rack1_id)) # the rack lives!
    assert(!DatacenterRackAssignment.exists?(bob_rack1_assignment_id))
  end
  
  
  def test_cant_delete_with_environment_assignment
    datacenter = Datacenter.create(:name => "Bob")
    environment = Environment.create(:name => 'bob-setup')
    assignment = DatacenterEnvironmentAssignment.create(:datacenter => datacenter, :environment => environment)
    
    assert_not_nil(datacenter)
    assert_not_nil(environment)
    assert_not_nil(assignment)
    assert_equal(1, datacenter.datacenter_environment_assignments.count) 
    assert_equal(1, datacenter.environments.count) 
    
    # Test that we can't destroy
    begin
      datacenter.destroy
    rescue Exception => destroy_error
      assert_equal(destroy_error.message, 'A datacenter can not be destroyed that has environments assigned to it.')
    else
      flunk('Trouble. We deleted a datacenter that had a environments assigned to it.')
    end
    
    # Remove the assignment, and make sure bob was destroyed
    assignment_id = assignment.id
    environment_id = environment.id
    datacenter_id = datacenter.id
    assignment.destroy
    datacenter.destroy
    assert(!Datacenter.exists?(datacenter_id))
    assert(Environment.exists?(environment_id))
    assert(!DatacenterEnvironmentAssignment.exists?(assignment_id))
  end
  
end
