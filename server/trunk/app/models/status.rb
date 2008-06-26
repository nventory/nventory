class Status < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_many :nodes
  has_many :programs
  
  validates_presence_of :name, :relevant_model
  validates_uniqueness_of :name, :scope => :relevant_model
  
  def self.relevant_models_allowed
    ['Node', 'Program']
  end
  
  def self.allowed_statuses_for_model(model)
    if self.relevant_models_allowed.include?(model.class.to_s)
      return self.find(:all, :conditions => ["relevant_model = ?", model.class.to_s], :order => 'name')
    end
  end
  
end
