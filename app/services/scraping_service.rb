require "open-uri"

class ScrapingService
  def initialize(url:, fields:, meta_tags:)
    @url = url
    @fields = fields
    @meta_tags = meta_tags
  end

  def call
    html = fetch_html
    doc = Nokogiri::HTML(html)

    results = scrape_fields(doc)
    meta_results = scrape_meta_tags(doc)

    { "fields" => results, "meta" => meta_results }
  end

  private

  def fetch_html
    Rails.cache.fetch(@url, expires_in: AppConfig::CACHE_EXPIRATION_TIME) do
      URI.open(@url, "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36").read
    end
  end

  def scrape_fields(doc)
    results = {}
    @fields.each do |name, selector|
      element = doc.css(selector)
      results[name] = element.any? ? element.text.strip : "N/A"
    end
    results
  end

  def scrape_meta_tags(doc)
    meta_results = {}
    @meta_tags.each do |meta_tag_name|
      meta_tag = doc.at("meta[name='#{meta_tag_name}']") || doc.at("meta[property='#{meta_tag_name}']")
      meta_results[meta_tag_name] = meta_tag ? meta_tag["content"] : "N/A"
    end
    meta_results
  end
end
