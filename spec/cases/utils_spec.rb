require 'spec_helper'

describe Koala::Utils do
  describe "#deprecate" do    
    before :each do
      # unstub deprecate so we can test it
      Koala::Utils.unstub(:deprecate)
    end
    
    it "has a deprecation prefix that includes the words Koala and deprecation" do
      Koala::Utils::DEPRECATION_PREFIX.should =~ /koala/i
      Koala::Utils::DEPRECATION_PREFIX.should =~ /deprecation/i      
    end
    
    it "prints a warning with Kernel.warn" do
      message = Time.now.to_s + rand.to_s
      Kernel.should_receive(:warn)
      Koala::Utils.deprecate(message)
    end

    it "prints the deprecation prefix and the warning" do
      message = Time.now.to_s + rand.to_s
      Kernel.should_receive(:warn).with(Koala::Utils::DEPRECATION_PREFIX + message)
      Koala::Utils.deprecate(message)
    end
    
    it "only prints each unique message once" do
      message = Time.now.to_s + rand.to_s
      Kernel.should_receive(:warn).once
      Koala::Utils.deprecate(message)
      Koala::Utils.deprecate(message)
    end
  end
end