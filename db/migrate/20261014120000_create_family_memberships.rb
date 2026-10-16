class CreateFamilyMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :family_memberships, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :family, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.string :role, null: false, default: "member"
      t.timestamps
    end

    add_index :family_memberships, [:user_id, :family_id], unique: true
    add_index :family_memberships, [:family_id, :role]

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO family_memberships (id, user_id, family_id, role, created_at, updated_at)
          SELECT gen_random_uuid(), id, family_id,
                 CASE WHEN role = 'super_admin' THEN 'admin' ELSE role END,
                 CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
          FROM users
          WHERE family_id IS NOT NULL
          ON CONFLICT (user_id, family_id) DO NOTHING
        SQL
      end
    end
  end
end
