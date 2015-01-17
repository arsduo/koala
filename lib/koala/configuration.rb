module Koala
  class Configuration
    # Allow an array of non-enumerables to be passed as is to Facebook
    attr_accessor :allow_array_parameters

    # Sets which Facebook API version to use (e.g. v1.0, v2.0, etc...)
    attr_accessor :api_version

    # Certain Facebook services (beta, video) require you to access different
    # servers. If you're using your own servers, for instance, for a proxy,
    # you can change both the matcher and the replacement values.
    # So for instance, if you're talking to fbproxy.mycompany.com, you could
    # set up beta.fbproxy.mycompany.com for FB's beta tier, and set the
    # matcher to /\.fbproxy/ and the beta_replace to '.beta.fbproxy'.
    attr_accessor :beta_replace, :host_path_matcher, :video_replace

    attr_accessor :dialog_host
    attr_accessor :graph_server
    attr_accessor :rest_server

    def initialize
      @allow_array_parameters = false
      @beta_replace           = '.beta.facebook'
      @dialog_host            = 'www.facebook.com'
      @graph_server           = 'graph.facebook.com'
      @host_path_matcher      = /\.facebook/
      @rest_server            = 'api.facebook.com'
      @video_replace          = '-video.facebook'
    end
  end
end
