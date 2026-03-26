class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :username, null: false, index: { unique: true }
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.integer :profile_visibility, default: 0
      
      t.timestamps
    end
    
    add_index :users, :username
    add_index :users, :email
  end
end