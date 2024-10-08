require "test_helper"

class ScrapeRequestTest < ActiveSupport::TestCase
  test "should not save ScrapeRequest without url" do
    scrape_request = ScrapeRequest.new(fields: { price: ".price-box__price" }, scraped_at: Time.now)
    assert_not scrape_request.save, "Saved the ScrapeRequest without a url"
  end

  test "should not save ScrapeRequest without scraped_at" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", fields: { price: ".price-box__price" })
    assert_not scrape_request.save, "Saved the ScrapeRequest without scraped_at"
  end

  test "should not save ScrapeRequest without fields or meta" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", scraped_at: Time.now)
    assert_not scrape_request.save, "Saved the ScrapeRequest without fields or meta"
  end

  test "should save ScrapeRequest with valid fields" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", fields: { price: ".price-box__price" }, scraped_at: Time.now)
    assert scrape_request.save, "Could not save a valid ScrapeRequest with fields"
  end

  test "should save ScrapeRequest with valid meta tags" do
    scrape_request = ScrapeRequest.new(url: "https://www.example.com", fields: {}, result: { "meta" => { "description" => "A great product" } }, scraped_at: Time.now)
    assert scrape_request.save, "Could not save a valid ScrapeRequest with meta tags"
  end

  test "should save ScrapeRequest with both fields and meta tags" do
    scrape_request = ScrapeRequest.new(
      url: "https://www.example.com",
      fields: { price: ".price-box__price" },
      result: { "meta" => { "description" => "A great product" } },
      scraped_at: Time.now
    )
    assert scrape_request.save, "Could not save a valid ScrapeRequest with both fields and meta tags"
  end
end
