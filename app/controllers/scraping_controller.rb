require "open-uri"

class ScrapingController < ApplicationController
  def index
    @recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    @previous_scrapes = ScrapeRequest.order(scraped_at: :desc).offset(1)
  end

  def create
    url = params[:url]

    fields = params[:fields].is_a?(Array) ? params[:fields].map { |field| [field[:name], field[:selector]] }.to_h : {}
    meta_tags = params[:meta] || []

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
      puts "Meta tags: #{meta_tags.inspect}"

      html = URI.open(url, "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
      doc = Nokogiri::HTML(html)

      results = {}
      fields.each do |name, selector|
        puts "Scraping field: #{name} with selector: #{selector}"
        element = doc.css(selector)
        results[name] = element.any? ? element.text.strip : "N/A"
      end

      meta_results = {}
      if meta_tags.any?
        meta_tags.each do |meta_tag_name|
          meta_tag = doc.at("meta[name='#{meta_tag_name}']") || doc.at("meta[property='#{meta_tag_name}']")
          meta_results[meta_tag_name] = meta_tag ? meta_tag["content"] : "N/A"
        end
      end

      host_name = URI.parse(url).host

      scrape_request = ScrapeRequest.create!(
        url: url,
        fields: fields,
        result: { "fields" => results, "meta" => meta_results },
        host: host_name,
        scraped_at: Time.now
      )

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
