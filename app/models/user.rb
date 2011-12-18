# coding: utf-8
class User < ActiveRecord::Base
  acts_as_authentic

  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_presence_of :first_name, :login, :email#, :last_name
  validates_presence_of :password, :on => :create


  has_and_belongs_to_many :roles
  has_and_belongs_to_many :groups

  scope :login_or_name_like, lambda { |text|
    where('LOWER(login) like :text OR LOWER(first_name) like :text OR LOWER(last_name) like :text',
          { :text => "%#{text.try(:downcase)}%" })
  }

  scope :admin, where(:is_admin => true)
  scope :no_admin, where(:is_admin => false)

  scope :by_site, lambda { |site_id|
    select("DISTINCT users.* ").
    joins('LEFT JOIN roles_users ON roles_users.user_id = users.id 
           LEFT JOIN roles ON roles.id = roles_users.role_id').
    where(["roles.site_id = ?", site_id])           
  }

  scope :global_role, lambda { select("DISTINCT users.* ").
    joins('LEFT JOIN roles_users ON roles_users.user_id = users.id 
           LEFT JOIN roles ON roles.id = roles_users.role_id').
    where(["roles.site_id IS NULL"])
  }

  scope :by_no_site, lambda { |site_id|
    where "not exists (#{
      Role.joins('INNER JOIN roles_users ON 
      roles_users.role_id = roles.id AND users.id = roles_users.user_id').
      where(:site_id => site_id).to_sql
    })" 
  }

  def name_or_login
    self.first_name ? ("#{self.first_name} #{self.last_name}") : self.login
  end

  def email_address_with_name
    self.first_name ? "#{self.first_name} #{self.last_name} <#{self.email}>" : "#{self.login} <#{self.email}>"
  end

  def active?
    self.status
  end

  def activate!
    self.status = true
    save
  end

  def deactivate!
    self.status = false
    save
  end

  def password_reset!(host)
    reset_perishable_token!
    Notifier.password_reset_instructions(self, host).deliver
  end  

  def send_activation_instructions!(host)
    reset_perishable_token!
    Notifier.activation_instructions(self, host).deliver
  end

  def send_activation_confirmation!(host)
    reset_perishable_token!
    Notifier.activation_confirmation(self, host).deliver
  end
end
