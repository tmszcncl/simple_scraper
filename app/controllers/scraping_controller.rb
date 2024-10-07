class ScrapingController < ApplicationController
  def index
    @recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    @previous_scrapes = ScrapeRequest.order(scraped_at: :desc).offset(1)
  end

  def create
    url = params[:url]
    fields = params[:fields].map { |field| [field[:name], field[:selector]] }.to_h

    begin
      html = URI.open(url)
      doc = Nokogiri::HTML(html)
      results = {}

      fields.each do |name, selector|
        results[name] = doc.css(selector).text.strip
      end

      host_name = URI.parse(url).host

      scrape_request = ScrapeRequest.create!(
        url: url,
        fields: fields,
        result: results,
        host: host_name,
        scraped_at: Time.now
      )

      redirect_to root_path
    rescue => e
      flash[:error] = "Failed to scrape the page: #{e.message}"
      redirect_to root_path
    end
  end
end
