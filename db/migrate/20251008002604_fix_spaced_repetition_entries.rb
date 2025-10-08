class FixSpacedRepetitionEntries < ActiveRecord::Migration[8.0]
  def up
    # Drop the existing incomplete table
    drop_table :spaced_repetition_entries if table_exists?(:spaced_repetition_entries)
    
    # Create the complete table
    create_table :spaced_repetition_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :problem_title, null: false
      t.string :problem_slug, null: false
      t.string :leetcode_id, null: false
      t.datetime :first_solved_at, null: false
      t.datetime :last_reviewed_at
      t.integer :review_count, default: 0
      t.integer :difficulty_level, default: 1 # 1=easy, 2=medium, 3=hard
      t.float :ease_factor, default: 2.5 # SM-2 algorithm ease factor
      t.integer :interval_days, default: 1
      t.datetime :next_review_at
      t.boolean :mastered, default: false
      t.timestamps
    end

    add_index :spaced_repetition_entries, [:user_id, :problem_slug], unique: true
    add_index :spaced_repetition_entries, [:user_id, :next_review_at]
    add_index :spaced_repetition_entries, [:user_id, :mastered]
  end

  def down
    drop_table :spaced_repetition_entries
  end
end
