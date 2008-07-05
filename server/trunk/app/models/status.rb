class Status < ActiveRecord::Base
  
  acts_as_paranoid
  
  has_many :nodes
  has_many :programs
  
  validates_presence_of :name, :relevant_model
  validates_uniqueness_of :name, :scope => :relevant_model
  
  RELEVANT_MODELS = ['Node']
  def self.relevant_models_allowed
    return RELEVANT_MODELS
  end
  
  validates_inclusion_of :relevant_model,
                         :in => RELEVANT_MODELS,
                         :message => "not one of the allowed relevant " +
                            "models: #{RELEVANT_MODELS.join(',')}"

  def self.allowed_statuses_for_model(model)
    if self.relevant_models_allowed.include?(model.class.to_s)
      return self.find(:all, :conditions => ["relevant_model = ?", model.class.to_s], :order => 'name')
    end
  end
  
  def self.default_search_attribute
    'name'
  end
 
end
