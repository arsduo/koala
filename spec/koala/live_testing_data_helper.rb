module LiveTestingDataHelper
  # in RSpec 2, included example groups no longer share any hooks or state with outside examples 
  # even if in the same block
  # so we have to use a module to provide setup and teardown hooks for live testing
  
  def self.included(base)
    base.class_eval do
      before :each do
        @token = $testing_data["oauth_token"]
        raise Exception, "Must supply access token to run FacebookWithAccessTokenTests!" unless @token
      end
  
      after :each do 
        # clean up any temporary objects
        if @temporary_object_id
          puts "\nCleaning up temporary object #{@temporary_object_id.to_s}"
          result = @api.delete_object(@temporary_object_id)
          raise "Unable to clean up temporary Graph object #{@temporary_object_id}!" unless result
        end
      end
    end
  end
end