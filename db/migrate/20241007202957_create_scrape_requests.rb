class CreateScrapeRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :scrape_requests do |t|
      t.string :url
      t.json :fields
      t.datetime :scraped_at

      t.timestamps
    end
  end
end
