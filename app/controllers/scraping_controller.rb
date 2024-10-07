require 'nokogiri'
require 'open-uri'

class ScrapingController < ApplicationController
  def index
    @recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    @previous_scrapes = ScrapeRequest.order(scraped_at: :desc).offset(1)
  end

  def create
    url = params[:url]
    fields = params[:fields]

    begin
      html = URI.open(url)
      doc = Nokogiri::HTML(html)
      results = {}

      fields.each do |key, selector|
        results[key] = doc.css(selector).text.strip
      end

      scrape_request = ScrapeRequest.create!(
        url: url,
        fields: fields,
        result: results,
        scraped_at: Time.now
      )

      redirect_to root_path
    rescue => e
      flash[:error] = "Failed to scrape the page: #{e.message}"
      redirect_to root_path
    end
  end
end
