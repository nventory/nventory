class RackNodeAssignment < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  belongs_to :rack 
  belongs_to :node 
  
  acts_as_list :scope => :rack
  
  validates_presence_of :rack_id, :node_id
  validates_uniqueness_of :node_id
  
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
