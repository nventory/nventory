require File.dirname(__FILE__) + '/../test_helper'

class ProgramTest < Test::Unit::TestCase
  fixtures :programs

  def test_program_deletion_causes_environment_program_assignment_deletion
    environment = Environment.create(:name => 'Env1')
    customer = Customer.create(:name => 'gus')
    status = Status.create(:name => "Joke", :relevant_model => "Program")
    program = Program.create(:name => 'voodoopad', :customer => customer, :status => status)
    assignment = EnvironmentProgramAssignment.create(:environment => environment, :program => program)
    
    assert_equal(0, environment.errors.count)
    assert_equal(0, customer.errors.count)
    assert_equal(0, status.errors.count)
    assert_equal(0, program.errors.count)
    assert_equal(0, assignment.errors.count)
    assert_equal(1, program.environment_program_assignments.count) 
    assert_equal(1, program.environments.count) 
    
    assignment_id = assignment.id
    program_id = program.id
    customer_id = customer.id
    environment_id = environment.id
    program.destroy
    assert(Environment.exists?(environment_id))
    assert(!EnvironmentProgramAssignment.exists?(assignment_id))
    assert(!Program.exists?(program_id))
    assert(Customer.exists?(customer_id))
  end
  
end
