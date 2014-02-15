module CloudStack
  API_SOURCE_URL = 'https://cloudstack.apache.org/docs/api/apidocs-4.2/TOC_Root_Admin.html'
  CACHE_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'cache'))

  class APIConsole
    @@apiKey = 'Enter your API key here'
    @@secretKey = 'Enter your secret key here'
    @@baseURL = 'http://localhost:8080'
    @@apiPath = '/client/api?'
  end

end
