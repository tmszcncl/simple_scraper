class ScrapingController < ApplicationController
  def index
    @recent_scrape = ScrapeRequest.order(scraped_at: :desc).first
    @previous_scrapes = ScrapeRequest.order(scraped_at: :desc).offset(1)
  end

  def create
    url = params[:url]
    fields = sanitize_fields(params[:fields])
    meta_tags = params[:meta]&.reject(&:blank?) || []

    # Ensure URL starts with a valid protocol
    unless valid_url?(url)
      handle_invalid_url
      return
    end

    if fields.empty? && meta_tags.empty?
      handle_empty_fields_and_meta
      return
    end

    begin
      scraping_service = ScrapingService.new(url: url, fields: fields, meta_tags: meta_tags)
      results = scraping_service.call

      scrape_request = ScrapeRequest.create!(
        url: url,
        fields: fields,
        result: results,
        host: URI.parse(url),
        scraped_at: Time.now
      )

      respond_to do |format|
        format.html { redirect_to root_path, notice: "Scraping completed successfully." }
        format.json { render json: scrape_request, status: :created }
      end

    rescue => e
      handle_scraping_error(e)
    end
  end

  private

  def sanitize_fields(fields)
    return {} unless fields.is_a?(Array)

    fields&.reject { |field| field[:name].blank? || field[:selector].blank? }
           &.map { |field| [ field[:name], field[:selector] ] }&.to_h || {}
  end

  def valid_url?(url)
    url =~ /\Ahttps?:\/\//
  end

  def handle_invalid_url
    respond_to do |format|
      format.html do
        flash[:error] = "Invalid URL format."
        redirect_to root_path
      end
      format.json do
        render json: { error: "Invalid URL format." }, status: :unprocessable_entity
      end
    end
  end

  def handle_empty_fields_and_meta
    respond_to do |format|
      format.html do
        flash[:error] = "Either fields or meta tags must be present"
        redirect_to root_path
      end
      format.json do
        render json: { error: "Either fields or meta tags must be present" }, status: :unprocessable_entity
      end
    end
  end

  def handle_scraping_error(exception)
    respond_to do |format|
      format.html do
        flash[:error] = "Failed to scrape the page: #{exception.message}"
        redirect_to root_path
      end
      format.json do
        render json: { error: exception.message }, status: :unprocessable_entity
      end
    end
  end
end
