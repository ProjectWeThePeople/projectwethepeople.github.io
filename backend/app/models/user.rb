class User < ApplicationRecord
  has_secure_password
  
  # Associations
  has_many :circles, dependent: :destroy
  has_many :outgoing_connections, class_name: 'Connection', foreign_key: 'from_user_id', dependent: :destroy
  has_many :incoming_connections, class_name: 'Connection', foreign_key: 'to_user_id', dependent: :destroy
  has_many :shared_circles, class_name: 'Share', foreign_key: 'shared_by_user_id', dependent: :destroy
  has_many :received_shares, class_name: 'Share', foreign_key: 'shared_with_user_id', dependent: :destroy
  
  # Through associations for easier access
  has_many :connected_users, through: :outgoing_connections, source: :to_user
  has_many :connecting_users, through: :incoming_connections, source: :from_user
  
  # Validations
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 30 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :profile_visibility, inclusion: { in: %w[public private friends_only] }
  
  # Enums
  enum :profile_visibility, { public: 0, private: 1, friends_only: 2 }
  
  # Callbacks
  before_save { self.email = email.downcase }
  before_save { self.username = username.downcase }
  
  # Instance methods
  def create_circle(attributes = {})
    circles.create(attributes)
  end
  
  def share_circle(circle_id, user_id, permission_level = 'view')
    circle = circles.find(circle_id)
    return false unless circle
    
    Share.create(
      circle: circle,
      shared_by_user: self,
      shared_with_user_id: user_id,
      permission_level: permission_level
    )
  end
  
  def connect_to_user(user_id, connection_type = 'friend_request')
    return false if user_id == id
    
    outgoing_connections.create(
      to_user_id: user_id,
      connection_type: connection_type,
      status: 'pending'
    )
  end
  
  def get_accessible_circles
    own_circles = circles.where(is_public: true).or(circles)
    shared_circles = Circle.joins(:shares).where(shares: { shared_with_user_id: id })
    
    Circle.where(id: own_circles.or(shared_circles).select(:id))
  end
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def display_name
    full_name.present? ? full_name : username
  end
end