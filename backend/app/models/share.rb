class Share < ApplicationRecord
  belongs_to :circle
  belongs_to :shared_by_user, class_name: 'User'
  belongs_to :shared_with_user, class_name: 'User'
  
  # Validations
  validates :circle_id, presence: true
  validates :shared_by_user_id, presence: true
  validates :shared_with_user_id, presence: true
  validates :permission_level, inclusion: { in: %w[view comment edit admin] }
  validate :owner_cannot_share_with_self
  validate :owner_must_be_circle_owner
  validate :unique_share_per_user
  
  # Enums
  enum permission_level: {
    view: 0,      # Can only view the circle and radians
    comment: 1,   # Can view and add comments (future feature)
    edit: 2,      # Can add/edit/remove radians
    admin: 3      # Can edit circle settings and manage other shares
  }
  
  # Scopes
  scope :active, -> { joins(:circle).where.not(circles: { user_id: nil }) }
  scope :for_user, ->(user_id) { where(shared_with_user_id: user_id) }
  scope :by_permission, ->(level) { where(permission_level: level) }
  
  # Instance methods
  def revoke_access!
    destroy!
  end
  
  def update_permissions!(new_level)
    return false unless %w[view comment edit admin].include?(new_level)
    
    update!(permission_level: new_level)
  end
  
  def can_view?
    true # All permission levels can view
  end
  
  def can_comment?
    comment? || edit? || admin?
  end
  
  def can_edit?
    edit? || admin?
  end
  
  def can_admin?
    admin?
  end
  
  def can_manage_shares?
    admin?
  end
  
  def permission_description
    case permission_level
    when 'view'
      'Can view circle and radians'
    when 'comment'
      'Can view and comment on radians'
    when 'edit'
      'Can view, comment, and edit radians'
    when 'admin'
      'Full access including sharing management'
    end
  end
  
  def shared_circle_title
    circle&.title || 'Unknown Circle'
  end
  
  def sharer_name
    shared_by_user&.display_name || 'Unknown User'
  end
  
  def recipient_name
    shared_with_user&.display_name || 'Unknown User'
  end
  
  # Class methods
  def self.for_circle_and_user(circle_id, user_id)
    find_by(circle_id: circle_id, shared_with_user_id: user_id)
  end
  
  def self.user_has_access?(circle_id, user_id, required_level = 'view')
    share = for_circle_and_user(circle_id, user_id)
    return false unless share
    
    case required_level
    when 'view'
      share.can_view?
    when 'comment'
      share.can_comment?
    when 'edit'
      share.can_edit?
    when 'admin'
      share.can_admin?
    else
      false
    end
  end
  
  def self.accessible_circles_for_user(user_id)
    Circle.joins(:shares)
          .where(shares: { shared_with_user_id: user_id })
          .distinct
  end
  
  private
  
  def owner_cannot_share_with_self
    if circle && shared_with_user_id == circle.user_id
      errors.add(:shared_with_user, "cannot share circle with yourself")
    end
  end
  
  def owner_must_be_circle_owner
    if circle && shared_by_user_id != circle.user_id
      errors.add(:shared_by_user, "must be the circle owner to share")
    end
  end
  
  def unique_share_per_user
    existing = Share.where(
      circle_id: circle_id,
      shared_with_user_id: shared_with_user_id
    ).where.not(id: id)
    
    if existing.exists?
      errors.add(:base, "Circle already shared with this user")
    end
  end
end