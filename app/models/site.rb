class Site < ActiveRecord::Base
  default_scope :order => 'id DESC'

  def array_per_page
    self.itens_per_page.delete(' ').split(',')
  end

  def to_param
    "#{name}"
  end

  def self.search(search, page, order = 'id desc', per_page = 20)
    paginate :per_page => per_page, :page => page, :conditions => ['lower(name) LIKE ? OR lower(description) LIKE ?', "%#{search}%", "%#{search}%"],
    :order => order
  end

  validates_presence_of :name, :url
  validates_uniqueness_of :name

  has_many :roles

  has_many :sites_menus
  has_many :menus, :through => :sites_menus

  has_many :sites_pages
  has_many :pages, :through => :sites_pages

  has_many :groups
  has_many :feedbacks
  has_many :banners

  has_many :sites_csses
  has_many :csses, :through => :sites_csses

  #accepts_nested_attributes_for :sites_users, :allow_destroy => true#, :reject_if => proc { |attributes| attributes['title'].blank? }
  accepts_nested_attributes_for :sites_menus, :allow_destroy => true#, :reject_if => proc { |attributes| attributes['title'].blank? }
  accepts_nested_attributes_for :sites_pages, :allow_destroy => true#, :reject_if => proc { |attributes| attributes['title'].blank? }

  belongs_to :repository, :foreign_key => "top_banner_id"
  has_many :repositories

  has_attached_file :top_banner, :url => "/uploads/:site_id/:style_:basename.:extension"

end
