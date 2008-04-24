class NodeFunctionAssignment < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  belongs_to :node
  belongs_to :function 
  
  validates_presence_of :node_id, :function_id
  
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
  def before_destroy
    if self.function.function_type.enables_database_instance_access? and self.node.node_database_instance_assignments.count > 0
      raise "This function assignment can not be deleted while the node is managing database instances."
    end
  end
  
end
