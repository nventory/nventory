class EnvironmentNodeAssignment < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  belongs_to :environment
  belongs_to :node 
  
  validates_presence_of :environment_id, :node_id
  
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
