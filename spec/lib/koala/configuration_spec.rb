require 'spec_helper'

describe Koala::Configuration do
  # Default Koala::Configuration settings
  its(:allow_array_parameters) { should eq false }
  its(:api_version) { should eq nil }
  its(:beta_replace) { should eq '.beta.facebook' }
  its(:dialog_host) { should eq 'www.facebook.com' }
  its(:graph_server) { should eq 'graph.facebook.com' }
  its(:host_path_matcher) { should eq(/\.facebook/) }
  its(:rest_server) { should eq 'api.facebook.com' }
  its(:video_replace) { should eq '-video.facebook' }

  # Koala::Configuration options should be overwritable
  it { should respond_to :allow_array_parameters= }
  it { should respond_to :api_version= }
  it { should respond_to :beta_replace= }
  it { should respond_to :dialog_host= }
  it { should respond_to :graph_server= }
  it { should respond_to :host_path_matcher= }
  it { should respond_to :rest_server= }
  it { should respond_to :video_replace= }
end
