class RemoveRuntimeAndMemoryFromSubmissions < ActiveRecord::Migration[8.0]
  def change
    remove_column :submissions, :runtime_ms, :integer
    remove_column :submissions, :memory_mb, :integer
  end
end
