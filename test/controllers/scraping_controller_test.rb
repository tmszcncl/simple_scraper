require "test_helper"
require "webmock/minitest"

class ScrapingControllerTest < ActionDispatch::IntegrationTest
  def setup
    stub_request(:get, "http://example.com/")
      .with(headers: {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      })
      .to_return(status: 200, body: "<html><body><div class='price'>100 USD</div></body></html>", headers: {})
  end

  test "should get index" do
    get root_url
    assert_response :success
    assert_select "h1", "Simple Scraper"
  end

  test "index should show recent scrape if present" do
    scrape_request = ScrapeRequest.create!(
      url: "http://example.com",
      fields: { "price" => ".price" },
      result: { "price" => "100 USD" },
      host: "example.com",
      scraped_at: Time.now
    )

    get root_url
    assert_response :success
    assert_select "h2", "Most Recent Result"
    assert_select "td", "price"
    assert_select "td", "100 USD"
  end

  test "index should handle no scrapes gracefully" do
    get root_url
    assert_response :success
    assert_select "h2", "Most Recent Result", false
    assert_select "h2", "Scraping History", false
  end

  test "should create scrape request" do
    assert_difference('ScrapeRequest.count', 1) do
      post scraping_url, params: {
        url: "http://example.com",
        fields: [
          { name: "price", selector: ".price" }
        ]
      }
    end

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success

    recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    assert_equal "http://example.com", recent_scrape.url
    assert_equal({ "price" => ".price" }, recent_scrape.fields)

    assert_select "h2", "Most Recent Result"
    assert_select "td", "price"
    assert_select "td", "100 USD"
  end

  test "should handle scraping errors" do
    post scraping_url, params: {
      url: "invalid-url",
      fields: [
        { name: "price", selector: ".price" }
      ]
    }

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_match "Failed to scrape the page", flash[:error]
  end
end
