shared_examples_for "live testing examples" do
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