class ScrapeRequest < ApplicationRecord
  validates :url, presence: true, format: URI.regexp(%w[http https])
  validates :scraped_at, presence: true
  validate :fields_or_meta_present

  private

  def fields_or_meta_present
    if fields.blank? && (result.nil? || result["meta"].blank?)
      errors.add(:base, "Either fields or meta must be present")
    end
  end
end
