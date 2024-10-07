class AddResultToScrapeRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :scrape_requests, :result, :json
  end
end
