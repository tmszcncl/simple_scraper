class AddHostToScrapeRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :scrape_requests, :host, :string
  end
end
