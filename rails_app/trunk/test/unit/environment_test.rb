require File.dirname(__FILE__) + '/../test_helper'

class EnvironmentTest < Test::Unit::TestCase
  fixtures :environments

  def test_environment_deletion_causes_datacenter_environment_assignment_deletion
    datacenter = Datacenter.create(:name => 'Billy')
    environment = Environment.create(:name => 'Env1')
    assignment = DatacenterEnvironmentAssignment.create(:datacenter => datacenter, :environment => environment)
    
    assert_not_nil(datacenter)
    assert_not_nil(environment)
    assert_not_nil(assignment)
    assert_equal(1, datacenter.datacenter_environment_assignments.count) 
    assert_equal(1, datacenter.environments.count) 
    
    assignment_id = assignment.id
    environment_id = environment.id
    datacenter_id = datacenter.id
    environment.destroy
    assert(!Environment.exists?(environment_id))
    assert(Datacenter.exists?(datacenter_id))
    assert(!DatacenterEnvironmentAssignment.exists?(assignment_id))
  end
  
  def test_environment_deletion_causes_environment_program_assignment_deletion
    environment = Environment.create(:name => 'Env1')
    customer = Customer.create(:name => 'gus')
    status = Status.create(:name => "Joke", :relevant_model => "Program")
    program = Program.create(:name => 'voodoopad', :customer => customer, :status => status)
    assignment = EnvironmentProgramAssignment.create(:environment => environment, :program => program)
    
    assert_equal(0, environment.errors.count)
    assert_equal(0, customer.errors.count)
    assert_equal(0, program.errors.count)
    assert_equal(0, assignment.errors.count)
    assert_equal(1, environment.environment_program_assignments.count) 
    assert_equal(1, environment.programs.count) 
    
    assignment_id = assignment.id
    program_id = program.id
    customer_id = customer.id
    environment_id = environment.id
    environment.destroy
    assert(!Environment.exists?(environment_id))
    assert(!EnvironmentProgramAssignment.exists?(assignment_id))
    assert(Program.exists?(program_id))
    assert(Customer.exists?(customer_id))

  end
  
  def test_environment_deletion_causes_environment_node_assignment_deletion
    environment = Environment.create(:name => 'Env1')
    node = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    assignment = EnvironmentNodeAssignment.create(:environment => environment, :node => node)
    
    assert_not_nil(environment)
    assert_not_nil(node)
    assert_not_nil(assignment)
    assert_equal(1, environment.environment_node_assignments.count) 
    assert_equal(1, environment.nodes.count) 
    
    assignment_id = assignment.id
    node_id = node.id
    environment_id = environment.id
    environment.destroy
    assert(!Environment.exists?(environment_id))
    assert(!EnvironmentNodeAssignment.exists?(assignment_id))
    assert(Node.exists?(node_id))

  end
  
end
