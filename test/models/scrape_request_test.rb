require "test_helper"

class ScrapeRequestTest < ActiveSupport::TestCase
  test "should not save ScrapeRequest without url" do
    scrape_request = ScrapeRequest.new(fields: { price: ".price-box__price" }, scraped_at: Time.now)
    assert_not scrape_request.save, "Saved the ScrapeRequest without a url"
  end

  test "should not save ScrapeRequest without fields" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", scraped_at: Time.now)
    assert_not scrape_request.save, "Saved the ScrapeRequest without fields"
  end

  test "should not save ScrapeRequest without scraped_at" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", fields: { price: ".price-box__price" })
    assert_not scrape_request.save, "Saved the ScrapeRequest without scraped_at"
  end

  test "should save valid ScrapeRequest" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", fields: { price: ".price-box__price" }, scraped_at: Time.now)
    assert scrape_request.save, "Could not save a valid ScrapeRequest"
  end

  test "should save ScrapeRequest with result" do
    scrape_request = ScrapeRequest.new(
      url: "https://www.example.com",
      fields: { price: ".price-box__price" },
      result: { price: "1000" },
      scraped_at: Time.now
    )
    assert scrape_request.save, "Could not save ScrapeRequest with a result"
  end
end
