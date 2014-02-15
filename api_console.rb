require 'open-uri'
require 'nokogiri'
require 'pry'
require 'digest/hmac'
require 'cgi'
require 'base64'

module CloudStack
  class APIConsole

    def initialize
      load_api_methods
      puts "Welcome to Pry-based CloudStack API Console!"
      puts "Just type 'singleton_methods' to see defined methods."
      unless @@apiKey.index(' ') == nil and @@secretKey.index(' ') == nil and @@baseURL and @@apiPath
        puts <<EOF

You have to set @@apiKey, @@secretKey, @@baseURL, @@apiPath first.
Edit "config.rb" or set those variables via the console temporarily.
EOF
      end
    end

    def cache_get(url)
      cache_file = File.join(CACHE_DIR, File.basename(url))
      unless File.exists? cache_file
        f = open(cache_file, "w")
        f.write(open(url).read)
        f.close
      end
      open(cache_file, "r").read
    end

    def load_api_methods
      html = Nokogiri::HTML.parse(cache_get(API_SOURCE_URL))

      urls = html.search('a').map{ |a|
        a.attributes['href'].value
      }.select{ |path|
        path.index('root_admin')
      }

      urls.each do |path|
        api = path.gsub(/^root_admin\/|\.html$/, '')
        self.define_singleton_method(api.to_sym) do |params = {}|
          if params.instance_of? Hash
            callApi api, params
          else
            apiHelp path
          end
        end
      end
    end

    def apiHelp(path)
      html = Nokogiri::HTML.parse( cache_get(File.join(File.dirname(API_SOURCE_URL), path)) )

      request_parameters = []
      html.search('table')[0].search('tr').map{ |tr|
        tr.search('td').map{|td| td.children.text}
      }[1..-1].each{ |params|
        request_parameters << {
          :name => params[0],
          :description => params[1],
          :required => eval(params[2])
        }
      }

      response_tags = []
      html.search('table')[1].search('tr').map{ |tr|
        tr.search('td').map{|td| td.children.text}
      }[1..-1].each{ |params|
        response_tags << {
          :name => params[0],
          :description => params[1]
        }
      }

      {
        :request_parameters => request_parameters.sort_by{|name, description, required| required },
        :response_tags => response_tags
      }
    end

    def callApi(command, args = {})
      request_params = {
        "command" => command,
        "apiKey" => @@apiKey
      }

      args.each{ |key, value|
        request_params[key.to_s] = value.to_s
      }

      digest_data = request_params.map{ |key, value|
        key + '=' + CGI.escape(value)
      }.sort.map{ |param|
        param.downcase
      }.join('&')

      request_params["signature"] = CGI.escape(Base64.encode64(Digest::HMAC.digest(digest_data, @@secretKey, Digest::SHA1)).chomp)

      url = @@baseURL + @@apiPath + request_params.map{ |key, value|
        key + '=' + value
      }.join('&').gsub('+', '%20')

      begin
        REXML::Document.new(open(url)).elements[command.downcase + "response"].elements.to_hash
      rescue => e
        REXML::Document.new(e.instance_variable_get("@io").read).elements[command.downcase + "response"].elements.to_hash
      end

    end

    def help
      nil
    end

    def console
      Kernel.binding.pry :quiet => true, :prompt => [Proc.new{"cloudstack> "}, Proc.new{"cloudstack: "}]
    end

  end
end

