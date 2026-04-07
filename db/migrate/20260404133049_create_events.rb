class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :group, null: false, foreign_key: true
      t.string     :title,          null: false
      t.text       :description
      t.datetime   :starts_at,      null: false
      t.datetime   :ends_at,        null: false
      t.string     :location
      t.string     :status,         null: false, default: "draft"
      t.string     :visibility,     null: false, default: "public"
      t.integer    :rsvp_limit
      t.datetime   :rsvp_opens_at
      t.datetime   :rsvp_closes_at

      t.timestamps
    end

    add_index :events, [ :group_id, :status ]
    add_index :events, :starts_at
  end
end
