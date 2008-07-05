class EnvironmentProgramAssignment < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :environment
  belongs_to :program 
  
  validates_presence_of :environment_id, :program_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
