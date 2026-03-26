class Connection < ApplicationRecord
  belongs_to :from_user, class_name: 'User'
  belongs_to :to_user, class_name: 'User'
  
  # Validations
  validates :from_user_id, presence: true
  validates :to_user_id, presence: true
  validates :connection_type, inclusion: { in: %w[friend_request mentor_request collaboration_request] }
  validates :status, inclusion: { in: %w[pending accepted declined blocked] }
  validate :cannot_connect_to_self
  validate :unique_connection_pair
  
  # Enums
  enum connection_type: {
    friend_request: 0,
    mentor_request: 1,
    collaboration_request: 2
  }
  
  enum status: {
    pending: 0,
    accepted: 1,
    declined: 2,
    blocked: 3
  }
  
  # Scopes
  scope :active, -> { where(status: 'accepted') }
  scope :pending_requests, -> { where(status: 'pending') }
  scope :for_user, ->(user_id) { where('from_user_id = ? OR to_user_id = ?', user_id, user_id) }
  
  # Instance methods
  def accept!
    return false unless pending?
    
    update!(status: 'accepted')
    
    # Create reciprocal connection for friend requests
    if friend_request?
      reciprocal = Connection.find_or_create_by(
        from_user: to_user,
        to_user: from_user,
        connection_type: connection_type
      )
      reciprocal.update!(status: 'accepted')
    end
    
    true
  end
  
  def decline!
    update!(status: 'declined')
  end
  
  def block!
    update!(status: 'blocked')
    
    # Block reciprocal connection if it exists
    reciprocal = Connection.find_by(from_user: to_user, to_user: from_user)
    reciprocal&.update!(status: 'blocked')
  end
  
  def other_user(current_user)
    return to_user if from_user == current_user
    return from_user if to_user == current_user
    nil
  end
  
  def can_see_circles?(user)
    return false unless accepted?
    return true if friend_request?
    
    # Other connection types might have different rules
    case connection_type
    when 'mentor_request'
      # Mentees can see mentor's public circles, mentors can see mentee's shared circles
      user == to_user
    when 'collaboration_request'
      true
    else
      false
    end
  end
  
  # Class methods
  def self.between_users(user1, user2)
    where(
      '(from_user_id = ? AND to_user_id = ?) OR (from_user_id = ? AND to_user_id = ?)',
      user1.id, user2.id, user2.id, user1.id
    )
  end
  
  def self.connection_exists?(user1, user2)
    between_users(user1, user2).exists?
  end
  
  private
  
  def cannot_connect_to_self
    errors.add(:to_user, "cannot connect to yourself") if from_user_id == to_user_id
  end
  
  def unique_connection_pair
    existing = Connection.where(
      '(from_user_id = ? AND to_user_id = ?) OR (from_user_id = ? AND to_user_id = ?)',
      from_user_id, to_user_id, to_user_id, from_user_id
    ).where.not(id: id)
    
    if existing.exists?
      errors.add(:base, "Connection already exists between these users")
    end
  end
end