shared_examples_for "Koala RestAPI" do
  # REST_CALL
  describe "when making a rest request" do
    it "should use the proper path" do
      method = stub('methodName')
      @api.should_receive(:api).with(
        "method/#{method}",
        anything,
        anything,
        anything
      )

      @api.rest_call(method)
    end

    it "should always use the rest api" do
      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        hash_including(:rest_api => true)
      )

      @api.rest_call('anything')
    end

    it "should set the read_only option to true if the method is listed in the read-only list" do
      method = Koala::Facebook::RestAPI::READ_ONLY_METHODS.first

      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        hash_including(:read_only => true)
      )

      @api.rest_call(method)
    end

    it "should set the read_only option to false if the method is not inthe read-only list" do
      method = "I'm not a read-only method"

      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        hash_including(:read_only => false)
      )

      @api.rest_call(method)
    end


    it "should take an optional hash of arguments" do
      args = {:arg1 => 'arg1'}

      @api.should_receive(:api).with(
        anything,
        hash_including(args),
        anything,
        anything
      )

      @api.rest_call('anything', args)
    end

    it "should always ask for JSON" do
      @api.should_receive(:api).with(
        anything,
        hash_including('format' => 'json'),
        anything,
        anything
      )

      @api.rest_call('anything')
    end

    it "should pass any options provided to the API" do
      options = {:a => 2}

      @api.should_receive(:api).with(
        anything,
        hash_including('format' => 'json'),
        anything,
        hash_including(options)
      )

      @api.rest_call('anything', {}, options)
    end
    
    it "uses get by default" do
      @api.should_receive(:api).with(
        anything,
        anything,
        "get",
        anything
      )

      @api.rest_call('anything')
    end
    
    it "allows you to specify other http methods as the last argument" do
      method = 'bar'
      @api.should_receive(:api).with(
        anything,
        anything,
        method,
        anything
      )

      @api.rest_call('anything', {}, {}, method)
    end

    it "should throw an APIError if the result hash has an error key" do
      Koala.stub(:make_request).and_return(Koala::Response.new(500, {"error_code" => "An error occurred!"}, {}))
      lambda { @api.rest_call("koppel", {}) }.should raise_exception(Koala::Facebook::APIError)
    end

    describe "when making a FQL request" do
      it "should call fql.query method" do
        @api.should_receive(:rest_call).with(
          "fql.query", anything, anything
        ).and_return(Koala::Response.new(200, "2", {}))

        @api.fql_query stub('query string')
      end

      it "should pass a query argument" do
        query = stub('query string')

        @api.should_receive(:rest_call).with(
          anything, hash_including(:query => query), anything
        )

        @api.fql_query(query)
      end
      
      it "should pass on any other arguments provided" do
        args = {:a => 2}
        @api.should_receive(:rest_call).with(anything, hash_including(args), anything)
        @api.fql_query("a query", args)
      end
      
      it "should pass on any http options provided" do
        opts = {:a => 2}
        @api.should_receive(:rest_call).with(anything, anything, hash_including(opts))
        @api.fql_query("a query", {}, opts)
      end
    end
    
    describe "when making a FQL-multiquery request" do
      it "should call fql.multiquery method" do
        @api.should_receive(:rest_call).with(
          "fql.multiquery", anything, anything
        ).and_return(Koala::Response.new(200, "2", {}))

        @api.fql_multiquery stub('query string')
      end

      it "should pass a queries argument" do
        queries = stub('query string')
        queries_json = "some JSON"
        queries.stub(:to_json).and_return(queries_json)
        
        @api.should_receive(:rest_call).with(
          anything,
          hash_including(:queries => queries_json),
          anything
        )

        @api.fql_multiquery(queries)
      end
      
      it "should pass on any other arguments provided" do
        args = {:a => 2}
        @api.should_receive(:rest_call).with(anything, hash_including(args), anything)
        @api.fql_multiquery("a query", args)
      end
      
      it "should pass on any http options provided" do
        opts = {:a => 2}
        @api.should_receive(:rest_call).with(anything, anything, hash_including(opts))
        @api.fql_multiquery("a query", {}, opts)
      end
    end
  end
end

shared_examples_for "Koala RestAPI with an access token" do
  # FQL
  it "should be able to access public information via FQL" do
    result = @api.fql_query('select first_name from user where uid = 216743')
    result.size.should == 1
    result.first['first_name'].should == 'Chris'
  end

  it "should be able to access public information via FQL.multiquery" do
    result = @api.fql_multiquery(
      :query1 => 'select first_name from user where uid = 216743',
      :query2 => 'select first_name from user where uid = 2905623'
    )
    result.size.should == 2
    result.first["fql_result_set"].first['first_name'].should == 'Chris'
    result.last["fql_result_set"].first['first_name'].should == 'Alex'
  end

  it "should be able to access protected information via FQL" do
    # Tests agains the permissions fql table

    # get the current user's ID
    # we're sneakily using the Graph API, which should be okay since it has its own tests
    g = Koala::Facebook::GraphAPI.new(@token)
    id = g.get_object("me", :fields => "id")["id"]

    # now send a query about your permissions
    result = @api.fql_query("select read_stream from permissions where uid = #{id}")

    result.size.should == 1
    # we've verified that you have read_stream permissions, so we can test against that
    result.first["read_stream"].should == 1
  end
  
  
  it "should be able to access protected information via FQL.multiquery" do
    result = @api.fql_multiquery(
      :query1 => "select post_id from stream where source_id = me()", 
      :query2 => "select fromid from comment where post_id in (select post_id from #query1)", 
      :query3 => "select uid, name from user where uid in (select fromid from #query2)"
    )
    result.size.should == 3 
    # we can't test in any more detail
    # since we can't assume anything about whether you have friends or posts
  end

end


shared_examples_for "Koala RestAPI without an access token" do
  # FQL_QUERY
  describe "when making a FQL request" do
    it "should be able to access public information via FQL" do
      @result = @api.fql_query("select first_name from user where uid = 216743")
      @result.size.should == 1
      @result.first["first_name"].should == "Chris"
    end
    
    it "should be able to access public information via FQL.multiquery" do
      result = @api.fql_multiquery(
        :query1 => 'select first_name from user where uid = 216743',
        :query2 => 'select first_name from user where uid = 2905623'
      )
      result.size.should == 2
      result.first["fql_result_set"].first['first_name'].should == 'Chris'
      result.last["fql_result_set"].first['first_name'].should == 'Alex'
    end

    it "should not be able to access protected information via FQL" do
      lambda { @api.fql_query("select read_stream from permissions where uid = 216743") }.should raise_error(Koala::Facebook::APIError)
    end
    
    it "should not be able to access protected information via FQL.multiquery" do
      lambda { 
        @api.fql_multiquery(
          :query1 => "select post_id from stream where source_id = me()", 
          :query2 => "select fromid from comment where post_id in (select post_id from #query1)", 
          :query3 => "select uid, name from user where uid in (select fromid from #query2)"
        ) 
      }.should raise_error(Koala::Facebook::APIError)
    end
  end
end