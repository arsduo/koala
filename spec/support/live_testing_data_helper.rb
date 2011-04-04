module LiveTestingDataHelper
  # in RSpec 2, included example groups no longer share any hooks or state with outside examples
  # even if in the same block
  # so we have to use a module to provide setup and teardown hooks for live testing

  def self.included(base)
    base.class_eval do
      before :each do
        @token = $testing_data["oauth_token"]
        raise Exception, "Must supply access token to run FacebookWithAccessTokenTests!" unless @token
        # track temporary objects created
        @temporary_object_ids = []
      end

      after :each do
        # clean up any temporary objects
        @temporary_object_ids << @temporary_object_id if @temporary_object_id
        count = @temporary_object_ids.length
        errors = []

        if count > 0
          @temporary_object_ids.each do |id|
            # get our API
            api = @api || (@test_users ? @test_users.graph_api : nil)
            raise "Unable to locate API when passed temporary object to delete!" unless api

            # delete the object
            result = (api.delete_object(id) rescue false)
            # if we errored out or Facebook returned false, track that
            errors << id unless result
          end

          unless errors.length == 0
            puts "cleaned up #{count - errors.length} objects, but errored out on the following:\n #{errors.join(", ")}"
          end
        end
      end
    end
  end
end