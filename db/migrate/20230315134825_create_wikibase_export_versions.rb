class CreateWikibaseExportVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :wikibase_export_versions do |t|
      t.string :file_hash, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
