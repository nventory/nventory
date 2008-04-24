class FunctionType < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_many :functions
  
  validates_presence_of :name
  
  def before_destroy
    raise "A function type can not be destroyed that has functions using it." if self.functions.count > 0
  end
  
end
