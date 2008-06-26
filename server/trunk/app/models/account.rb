require 'digest/sha1'

class Account < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  validates_presence_of   :login, :email_address, :name
  validates_uniqueness_of :login, :email_address
 
  attr_accessor :password_confirmation
  validates_confirmation_of :password
 
  def validate
    errors.add("password", "can't be blank") if password_hash.blank?
  end
 
  def self.authenticate(login, password)
    account = self.find_by_login(login)
    if account
      expected_password = encrypted_password(password, account.password_salt)
      if account.password_hash != expected_password
        account = nil
      end
    end
    account
  end
 
  # 'password' is a virtual attribute
  def password
    @password
  end

  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.password_hash = Account.encrypted_password(self.password, self.password_salt)
  end
 
  private

  def self.encrypted_password(password, salt)
    string_to_hash = password + "this-is-better" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end
 
  def create_new_salt
    self.password_salt = self.object_id.to_s + rand.to_s
  end
 
end
