require "test_helper"
require "webmock/minitest"

class ScrapingControllerTest < ActionDispatch::IntegrationTest
  def setup
    stub_request(:get, "http://example.com/")
      .with(headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
      })
      .to_return(status: 200, body: "<html><meta name='description' content='Test description'></meta><div class='price'>100 USD</div></body></html>", headers: {})

    stub_request(:get, "http://invalid-url/")
      .with(headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
      })
      .to_return(status: 404, body: "Not Found", headers: {})
  end

  test "should create scrape request with meta tags only" do
    assert_difference("ScrapeRequest.count", 1) do
      post scraping_url, params: {
        url: "http://example.com",
        meta: ["description"]
      }, as: :json
    end

    assert_response :created
    recent_scrape = ScrapeRequest.order(scraped_at: :desc).first

    assert_equal "http://example.com", recent_scrape.url
    assert_empty recent_scrape.fields, "Fields should be empty"
    assert_equal({ "description" => "Test description" }, recent_scrape.result["meta"], "Meta tag scraping failed"
    )
  end

  test "should create scrape request with fields and meta tags" do
    assert_difference("ScrapeRequest.count", 1) do
      post scraping_url, params: {
        url: "http://example.com",
        fields: [
          { name: "price", selector: ".price" }
        ],
        meta: ["description"]
      }
    end

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success

    recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    assert_equal "http://example.com", recent_scrape.url
    assert_equal({ "price" => "100 USD" }, recent_scrape.result["fields"], "Fields scraping failed")
    assert_equal({ "description" => "Test description" }, recent_scrape.result["meta"], "Meta tag scraping failed")
  end

  test "should handle scraping without fields or meta tags" do
    assert_no_difference("ScrapeRequest.count") do
      post scraping_url, params: {
        url: "http://example.com"
      }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Either fields or meta tags must be present", json_response["error"]
  end

  test "should handle scraping errors via UI" do
    post scraping_url, params: {
      url: "http://invalid-url",
      fields: [
        { name: "price", selector: ".price" }
      ]
    }

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_match "Failed to scrape the page", flash[:error]
  end

  test "should handle scraping errors via API" do
    post scraping_url, params: {
      url: "http://invalid-url",
      fields: { price: ".price" }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Either fields or meta tags must be present", json_response["error"]
  end
end
