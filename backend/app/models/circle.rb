class Circle < ApplicationRecord
  belongs_to :user
  
  # Associations
  has_many :radians, dependent: :destroy
  has_many :shares, dependent: :destroy
  has_many :circle_snapshots, dependent: :destroy
  has_many :shared_with_users, through: :shares, source: :shared_with_user
  
  # Validations  
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :color_theme, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :user_id, presence: true
  
  # Enums
  enum visibility: { private: 0, public: 1, friends_only: 2 }
  
  # Callbacks
  before_create :set_initial_version
  before_update :increment_version_if_changed
  after_update :create_snapshot_if_significant_change
  
  # Scopes
  scope :public_circles, -> { where(is_public: true) }
  scope :recent, -> { order(updated_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  
  # Instance methods
  def add_radian(content, position_angle = nil)
    position_angle ||= calculate_next_position
    
    radians.create(
      content: content,
      position_angle: position_angle
    )
  end
  
  def remove_radian(radian_id)
    radian = radians.find(radian_id)
    return false unless radian
    
    radian.archive!
    rebalance_radians
  end
  
  def share_with_user(user_id, permission_level = 'view')
    return false if user_id == user.id
    
    shares.create(
      shared_with_user_id: user_id,
      permission_level: permission_level,
      shared_by_user: user
    )
  end
  
  def publish!
    update!(is_public: true)
    create_snapshot("Published publicly")
  end
  
  def create_snapshot(reason = nil)
    snapshot_data = {
      title: title,
      description: description,
      color_theme: color_theme,
      is_public: is_public,
      radians: radians.active.map(&:to_snapshot),
      created_at: Time.current,
      reason: reason
    }
    
    circle_snapshots.create!(
      snapshot_data: snapshot_data,
      version: version
    )
  end
  
  def get_radians_ordered
    radians.active.order(:position_angle)
  end
  
  def radian_count
    radians.active.count
  end
  
  def can_be_viewed_by?(viewer_user)
    return true if user == viewer_user
    return true if is_public?
    return shares.exists?(shared_with_user: viewer_user)
  end
  
  def can_be_edited_by?(editor_user)
    return true if user == editor_user
    return shares.where(shared_with_user: editor_user, permission_level: ['edit', 'admin']).exists?
  end
  
  private
  
  def set_initial_version
    self.version = 1
  end
  
  def increment_version_if_changed
    if title_changed? || description_changed? || radians.any?(&:changed?)
      self.version += 1
    end
  end
  
  def create_snapshot_if_significant_change
    if saved_change_to_title? || saved_change_to_description? || saved_change_to_is_public?
      create_snapshot("Automatic snapshot - significant changes")
    end
  end
  
  def calculate_next_position
    return 0.0 if radians.empty?
    
    # Distribute radians evenly around the circle
    active_count = radians.active.count
    (360.0 / (active_count + 1)) * active_count
  end
  
  def rebalance_radians
    active_radians = radians.active.order(:created_at)
    return if active_radians.empty?
    
    angle_step = 360.0 / active_radians.count
    
    active_radians.each_with_index do |radian, index|
      new_angle = angle_step * index
      radian.update_column(:position_angle, new_angle)
    end
  end
end