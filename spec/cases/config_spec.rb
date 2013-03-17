require 'spec_helper'

describe Koala::Config do
  describe '.config' do
    describe 'defaults' do
      it 'should define the graph server' do
        subject.graph_server.should == 'graph.facebook.com'
        subject[:graph_server].should == 'graph.facebook.com'
      end

      it 'should define the rest server' do
        subject.rest_server.should == 'api.facebook.com'
        subject[:rest_server].should == 'api.facebook.com'
      end

      it 'should define the dialog host' do
        subject.dialog_host.should == 'www.facebook.com'
        subject[:dialog_host].should == 'www.facebook.com'
      end

      it 'should define the path replacement regular expression' do
        subject.host_path_matcher.should == /\.facebook/
        subject[:host_path_matcher].should == /\.facebook/
      end

      it 'should define the video server replacement for uploads' do
        subject.video_replace.should == '-video.facebook'
        subject[:video_replace].should == '-video.facebook'
      end

      it 'should define the beta tier replacement' do
        subject.beta_replace.should == '.beta.facebook'
        subject[:beta_replace].should == '.beta.facebook'
      end
    end
  end

  describe 'assigning values' do
    [:graph_server, :some_other].each do |type|
      describe "when setting the #{type}" do
        before do
          subject.send("#{type}=", 'mock.graph_server.com')
        end

        it 'should take the new value' do
          subject.send(type).should == 'mock.graph_server.com'
          subject[type].should == 'mock.graph_server.com'
        end
      end
    end
  end
end
