ActionController::Routing::Routes.draw do |map|
  map.resources :function_types

  map.resources :accounts

  map.resources :database_instance_relationships

  
  map.resources :environment_node_assignments  
  map.resources :environment_program_assignments
  map.resources :datacenter_environment_assignments
  map.resources :environments
  map.resources :programs
  map.resources :customers
  map.resources :outlets
  map.resources :node_database_instance_assignments
  map.resources :database_instances
  map.resources :node_function_assignments
  map.resources :functions
  map.resources :statuses
  map.resources :subnets
  map.resources :node_groups
  map.resources :node_group_node_assignments
  map.resources :node_group_node_group_assignments
  map.resources :operating_systems
  map.resources :hardware_profiles
  map.resources :rack_node_assignments
  map.resources :nodes
  map.resources :network_interfaces
  map.resources :ip_addresses
  map.resources :datacenters
  map.resources :racks
  map.resources :datacenter_rack_assignments
  map.resources :vips
  map.resources :datacenter_vip_assignments

  # Add the version_history method to all the object routes
  map.resources :datacenters,                          :member => { :version_history => :get } 
  map.resources :datacenter_rack_assignments,          :member => { :version_history => :get } 
  map.resources :racks,                                :member => { :version_history => :get } 
  map.resources :rack_node_assignments,                :member => { :version_history => :get } 
  map.resources :nodes,                                :member => { :version_history => :get } 
  map.resources :network_interfaces,                   :member => { :version_history => :get } 
  map.resources :ip_addresses,                         :member => { :version_history => :get } 
  map.resources :hardware_profiles,                    :member => { :version_history => :get } 
  map.resources :operating_systems,                    :member => { :version_history => :get } 
  map.resources :statuses,                             :member => { :version_history => :get } 
  map.resources :subnets,                              :member => { :version_history => :get } 
  map.resources :node_groups,                          :member => { :version_history => :get } 
  map.resources :node_group_node_assignments,          :member => { :version_history => :get } 
  map.resources :node_group_node_group_assignments,    :member => { :version_history => :get } 
  map.resources :functions,                            :member => { :version_history => :get } 
  map.resources :node_function_assignments,            :member => { :version_history => :get } 
  map.resources :database_instances,                   :member => { :version_history => :get } 
  map.resources :node_database_instance_assignments,   :member => { :version_history => :get } 
  map.resources :outlets,                              :member => { :version_history => :get } 
  map.resources :customers,                            :member => { :version_history => :get } 
  map.resources :programs,                             :member => { :version_history => :get } 
  map.resources :environments,                         :member => { :version_history => :get } 
  map.resources :datacenter_environment_assignments,   :member => { :version_history => :get } 
  map.resources :environment_program_assignments,      :member => { :version_history => :get } 
  map.resources :environment_node_assignments,         :member => { :version_history => :get } 
  map.resources :database_instance_relationships,      :member => { :version_history => :get } 
  map.resources :accounts,                             :member => { :version_history => :get } 
  map.resources :function_types,                       :member => { :version_history => :get } 
  map.resources :vips,                                 :member => { :version_history => :get } 
  map.resources :datacenter_vip_assignments,           :member => { :version_history => :get } 

  # add get method that will return the consumer on this outlet (used in AJAX on Node page)
  map.resources :outlets, :member => { :consumer => :get } 
  
  # add get method that will return the visualization of this rack
  map.resources :racks,       :member => { :visualization => :get } 
  map.resources :datacenters, :member => { :visualization => :get } 

  map.resources :environments, :member => { :xml_configuration => :get } 

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "dashboard"
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
