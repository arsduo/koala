module Koala
  class Config
    def initialize
      @config = {
        'dialog_host' => 'www.facebook.com',
        'rest_server' => 'api.facebook.com',
        'graph_server' => 'graph.facebook.com',
        'host_path_matcher' => /\.facebook/,
        'video_replace' => '-video.facebook',
        'beta_replace' => '.beta.facebook'
      }
    end

    def [](key)
      @config[key.to_s]
    end

    def []=(key, value)
      @config[key.to_s] = value
    end

    def method_missing(method, *args)
      match = method.to_s.match(/(.+)(=)$/)

      if match && match[2]
        self[match[1]] = args.pop
      else
        self[method.to_s]
      end
    end
  end
end
