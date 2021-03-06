require 'wombat'
require 'httpclient'
require 'uri'

class Scrapers::Indeed
  def initialize country_code='ca'
    @country_code=country_code
  end

  def host
    "http://www.indeed.#{@country_code}"
  end

  def scrape query='ruby', pages=10
    jobs = (pages.times.collect do |page_no|
      country_code = @country_code
      limit = (page_no)*20
      base_url_val = host 

      page_results = Wombat.crawl do
        base_url(base_url_val)
        path "/jobs?q=#{query}&start=#{limit}"

        jobs 'css=#resultsCol>.row', :iterator do
          title 'css=h2>a'
          job_id 'css=h2 @id'
          link 'css=h2>a @href'
          company 'css=.company'
          location 'css=.location'
          summary 'css=.summary'
          days_ago 'css=.date'
          source 'css=.sdn'
          country_code country_code
        end
      end

      page_results['jobs']
    end).flatten

    jobs.each do |job|
      #job['link'] = get_final_uri("http://www.indeed.ca/#{job['link']}")
      job['link'] = "http://www.indeed.#{@country_code}#{job['link']}"
      job['days_ago'] = job['days_ago'].gsub(/ days ago/, '')
      #job['job_id'] = job['link'].gsub('http://www.indeed.ca/rc/clk?jk=', '')
    end
  end

  def get_final_uri uri
    follow_uri = uri
    httpc = HTTPClient.new

    while(true) do
      resp=httpc.get(follow_uri)
      if resp.redirect?
        if (path=resp.headers['Location']).include?('http')
          follow_uri = path
          next
        else
          follow_uri = "#{(URI.parse(follow_uri).path='').to_s}"
        end
      else
        return resp.headers['Location']
      end
    end
  end
end
