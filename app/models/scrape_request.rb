class ScrapeRequest < ApplicationRecord
  validates :url, presence: true, format: URI.regexp(%w[http https])
  validates :fields, presence: true
  validates :scraped_at, presence: true
end
