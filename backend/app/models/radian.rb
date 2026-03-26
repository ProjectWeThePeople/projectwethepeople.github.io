class Radian < ApplicationRecord
  belongs_to :circle
  
  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  validates :position_angle, presence: true, numericality: { in: 0..360 }
  validates :circle_id, presence: true
  
  # Scopes
  scope :active, -> { where(is_archived: false) }
  scope :archived, -> { where(is_archived: true) }
  scope :by_angle, -> { order(:position_angle) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_save :normalize_angle
  after_create :rebalance_circle_radians
  after_destroy :rebalance_circle_radians
  
  # Instance methods
  def update_content(new_content)
    return false if new_content.blank?
    
    update(content: new_content)
  end
  
  def move_position(new_angle)
    return false unless new_angle.is_a?(Numeric)
    
    normalized_angle = normalize_angle_value(new_angle)
    update(position_angle: normalized_angle)
  end
  
  def archive!
    update!(is_archived: true)
    circle.create_snapshot("Radian archived: #{content.truncate(50)}")
  end
  
  def restore!
    update!(is_archived: false)
    circle.create_snapshot("Radian restored: #{content.truncate(50)}")
  end
  
  def to_snapshot
    {
      id: id,
      content: content,
      position_angle: position_angle,
      created_at: created_at,
      updated_at: updated_at
    }
  end
  
  def angle_in_radians
    position_angle * (Math::PI / 180.0)
  end
  
  def x_coordinate(radius = 100)
    Math.cos(angle_in_radians) * radius
  end
  
  def y_coordinate(radius = 100)
    Math.sin(angle_in_radians) * radius
  end
  
  def coordinates(radius = 100)
    {
      x: x_coordinate(radius),
      y: y_coordinate(radius),
      angle: position_angle
    }
  end
  
  def word_count
    content.split.length
  end
  
  def character_count
    content.length
  end
  
  def can_be_edited_by?(user)
    circle.can_be_edited_by?(user)
  end
  
  def can_be_viewed_by?(user)
    circle.can_be_viewed_by?(user)
  end
  
  # Class methods
  def self.search_content(query)
    where("content ILIKE ?", "%#{query}%")
  end
  
  def self.within_angle_range(start_angle, end_angle)
    if start_angle <= end_angle
      where(position_angle: start_angle..end_angle)
    else
      # Handle wrap-around case (e.g., 350° to 10°)
      where("position_angle >= ? OR position_angle <= ?", start_angle, end_angle)
    end
  end
  
  private
  
  def normalize_angle
    self.position_angle = normalize_angle_value(position_angle) if position_angle_changed?
  end
  
  def normalize_angle_value(angle)
    # Ensure angle is between 0 and 360
    angle = angle % 360
    angle < 0 ? angle + 360 : angle
  end
  
  def rebalance_circle_radians
    return unless circle
    
    # Only rebalance if this radian affects the circle structure
    circle.send(:rebalance_radians) if circle.respond_to?(:rebalance_radians, true)
  end
end