class CreateGroupMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :group_memberships, [ :group_id, :user_id ], unique: true
    add_index :group_memberships, [ :group_id, :role ]
  end
end
