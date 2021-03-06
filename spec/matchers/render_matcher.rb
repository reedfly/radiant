module Spec
  module Rails
    module Matchers

      class RenderTags
        def initialize(content = nil)
          @content = content
        end

        def matches?(page)
          @actual = render_content_with_page(@content, page)
          if @expected.kind_of?(Regexp)
            @expected = nil
            @matching = @expected
          end
          case
            when @expected_error_message then false
            when @expected then @actual == @expected
            when @matching then @actual =~ @matching
            when @not_matching then @actual !~ @not_matching
            else true
          end
        rescue => @actual_error
          if @expected_error_message
            @actual_error.message === @expected_error_message
          else
            @error_thrown = true
            false
          end
        end

        def failure_message
          action = case
          when @expected
            "render as #{@expected.inspect}"
          when @not_matching
            "render but not match #{@not_matching.inspect}"
          else
            "render and match #{@matching.inspect}"
          end
          unless @error_thrown
            unless @expected_error_message
              if @content
                "expected #{@content.inspect} to #{action}, but got #{@actual.inspect}"
              else
                "expected page to #{action}, but got #{@actual.inspect}"
              end
            else
              if @actual_error
                "expected rendering #{@content.inspect} to throw exception with message #{@expected_error_message.inspect}, but was #{@actual_error.message.inspect}"
              else
                "expected rendering #{@content.inspect} to throw exception with message #{@expected_error_message.inspect}, but no exception thrown. Rendered #{@actual.inspect} instead."
              end
            end
          else
            "expected #{@content.inspect} to render, but an exception was thrown #{@actual_error.message}"
          end
        end

        def description
          "render tags #{@expected.inspect}"
        end

        def as(output)
          @expected = output
          self
        end

        def matching(regexp)
          @matching = regexp
          self
        end

        def not_matching(regexp)
          @not_matching = regexp
          self
        end

        def with_error(message)
          @expected_error_message = message
          self
        end

        def on(url)
          url = test_host + "/" + url unless url =~ %r{^[^/]+\.[^/]+}
          url = 'http://' + url unless url =~ %r{^http://}
          uri = URI.parse(url)
          @fullpath = uri.fullpath unless uri.fullpath == '/'
          @host = uri.host
          self
        end

        def with_relative_root(url="/")
          @relative_root = url
          self
        end

        private
          def render_content_with_page(tag_content, page)
            page.request = ActionController::TestRequest.new
            page.request.params[:sample_param] = 'data'
            page.request.fullpath = @fullpath || page.url
            page.request.host = @host || test_host
            ActionController::Base.relative_url_root = @relative_root
            page.response = ActionController::TestResponse.new
            if tag_content.nil?
              page.render
            else
              page.send(:parse, tag_content)
            end
          end

          def test_host
            "testhost.tld"
          end
      end

      # page.should render(input).as(output)
      # page.should render(input).as(output).on(url)
      # page.should render(input).matching(/hello world/)
      # page.should render(input).with_error(message)
      def render(input)
        RenderTags.new(input)
      end

      # page.should render_as(output)
      def render_as(output)
        RenderTags.new.as(output)
      end

    end
  end
end