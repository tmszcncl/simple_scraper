require "open-uri"

class ScrapingController < ApplicationController
  def index
    @recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    @previous_scrapes = ScrapeRequest.order(scraped_at: :desc).offset(1)
  end

  def create
    url = params[:url]

    if params[:fields].is_a?(Array)
      fields = params[:fields].map { |field| [ field[:name], field[:selector] ] }.to_h
    else
      fields = params[:fields].permit!.to_h
    end

    # Ensure URL starts with a valid protocol
    unless url =~ /\Ahttps?:\/\//
      respond_to do |format|
        format.html do
          flash[:error] = "Invalid URL format."
          redirect_to root_path
        end
        format.json do
          render json: { error: "Invalid URL format." }, status: :unprocessable_entity
        end
      end
      return
    end

    begin
      puts "Scraping URL: #{url}"
      puts "Fields: #{fields.inspect}"

      html = URI.open(url, "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
      doc = Nokogiri::HTML(html)
      results = {}

      fields.each do |name, selector|
        puts "Scraping field: #{name} with selector: #{selector}"
        element = doc.css(selector)
        puts "Found elements: #{element.inspect}"

        results[name] = element.any? ? element.text.strip : "N/A"
        puts "Scraped value: #{results[name]}"
      end

      host_name = URI.parse(url).host
      puts "Host: #{host_name}"

      scrape_request = ScrapeRequest.create!(
        url: url,
        fields: fields,
        result: results,
        host: host_name,
        scraped_at: Time.now
      )
      puts "Scrape request saved: #{scrape_request.inspect}"

      respond_to do |format|
        format.html { redirect_to root_path, notice: "Scraping completed successfully." }
        format.json { render json: scrape_request, status: :created }
      end

    rescue => e
      respond_to do |format|
        format.html do
          flash[:error] = "Failed to scrape the page: #{e.message}"
          redirect_to root_path
        end
        format.json do
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
