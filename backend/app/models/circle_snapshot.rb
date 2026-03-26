class CircleSnapshot < ApplicationRecord
  belongs_to :circle
  
  # Validations
  validates :circle_id, presence: true
  validates :version, presence: true, numericality: { greater_than: 0 }
  validates :snapshot_data, presence: true
  
  # Serialization
  serialize :snapshot_data, JSON
  
  # Scopes
  scope :ordered, -> { order(:version) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_version, ->(version_num) { where(version: version_num) }
  
  # Instance methods
  def restore_version!
    return false unless valid_snapshot?
    
    Circle.transaction do
      # Archive current radians
      circle.radians.active.update_all(is_archived: true)
      
      # Restore circle attributes
      circle.update!(
        title: snapshot_data['title'],
        description: snapshot_data['description'],
        color_theme: snapshot_data['color_theme'],
        is_public: snapshot_data['is_public']
      )
      
      # Recreate radians from snapshot
      snapshot_data['radians']&.each do |radian_data|
        circle.radians.create!(
          content: radian_data['content'],
          position_angle: radian_data['position_angle']
        )
      end
      
      # Create new snapshot for this restoration
      circle.create_snapshot("Restored to version #{version}")
      
      true
    end
  rescue => e
    Rails.logger.error "Failed to restore version #{version} for circle #{circle.id}: #{e.message}"
    false
  end
  
  def preview_data
    {
      version: version,
      title: snapshot_data['title'],
      description: snapshot_data['description'],
      radian_count: radian_count,
      created_at: created_at,
      reason: snapshot_data['reason']
    }
  end
  
  def radian_count
    snapshot_data['radians']&.length || 0
  end
  
  def snapshot_title
    snapshot_data['title'] || 'Untitled Circle'
  end
  
  def snapshot_description
    snapshot_data['description'] || ''
  end
  
  def change_reason
    snapshot_data['reason'] || 'No reason provided'
  end
  
  def radians_data
    snapshot_data['radians'] || []
  end
  
  def was_public?
    snapshot_data['is_public'] || false
  end
  
  def color_theme
    snapshot_data['color_theme']
  end
  
  def differences_from_current
    current_circle = circle
    changes = {}
    
    changes[:title] = {
      old: snapshot_data['title'],
      new: current_circle.title
    } if snapshot_data['title'] != current_circle.title
    
    changes[:description] = {
      old: snapshot_data['description'],
      new: current_circle.description
    } if snapshot_data['description'] != current_circle.description
    
    changes[:radian_count] = {
      old: radian_count,
      new: current_circle.radian_count
    } if radian_count != current_circle.radian_count
    
    changes[:publicity] = {
      old: was_public?,
      new: current_circle.is_public?
    } if was_public? != current_circle.is_public?
    
    changes
  end
  
  def export_data
    {
      circle_title: snapshot_title,
      version: version,
      created_at: created_at,
      snapshot_data: snapshot_data,
      metadata: {
        radian_count: radian_count,
        was_public: was_public?,
        change_reason: change_reason
      }
    }
  end
  
  # Class methods
  def self.latest_for_circle(circle_id)
    where(circle_id: circle_id).order(:version).last
  end
  
  def self.version_history(circle_id, limit = 10)
    where(circle_id: circle_id)
      .order(version: :desc)
      .limit(limit)
      .includes(:circle)
  end
  
  def self.find_version(circle_id, version_number)
    find_by(circle_id: circle_id, version: version_number)
  end
  
  def self.cleanup_old_snapshots(circle_id, keep_count = 20)
    snapshots = where(circle_id: circle_id).order(:version)
    
    if snapshots.count > keep_count
      snapshots.limit(snapshots.count - keep_count).destroy_all
    end
  end
  
  private
  
  def valid_snapshot?
    snapshot_data.is_a?(Hash) &&
      snapshot_data['title'].present? &&
      snapshot_data['radians'].is_a?(Array)
  end
end