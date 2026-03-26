class CreateCircleSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :circle_snapshots do |t|
      t.references :circle, null: false, foreign_key: true
      t.integer :version
      t.text :snapshot_data

      t.timestamps
    end
  end
end
