require 'spec_helper'

describe "Koala::Facebook::GraphAPI in batch mode" do
  include LiveTestingDataHelper
  
  # making requests
  it "makes batch requests for APIs with a token"
  it "makes batch requests for APIs without a token"
  it "makes batch requests for multiple APIs with and without tokens"
  it "uses ssl if any request includes an access token"
  it "uploads binary files appropriately"
  
  # batch interface
  it "sets the batch_mode flag inside batch mode"
  it "throws an error if you access the batch_calls queue outside a batch block"
  it "clears the batch queue between requests"
end