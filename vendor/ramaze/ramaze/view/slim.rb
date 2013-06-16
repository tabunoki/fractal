require 'slim'

module Innate
  module View
    ##
    # View adapter for the Slim template engine. For more information about Slim
    # see the following page: https://github.com/stonean/slim
    #
    # @example
    #  class MainController < Ramaze::Controller
    #    map    '/'
    #    engine :slim
    #
    #    def index
    #      # Create some data for the view and render it.
    #    end
    #  end
    #
    # @since 19-01-2012
    #
    module Slim
      ##
      # Compiles the view and returns the HTML and mime type.
      #
      # @since 19-01-2012
      # @param [Innate::Action] action The action for which to compile/render
      #  the view.
      # @param  [String] string The content of the view.
      # @return [Array] The HTML and MIME type.
      #
      def self.call(action, string)
        filename = action.view || action.method
        slim     = View.compile(string) do |str|
          ::Slim::Template.new(filename) { str }
        end

        html = slim.render(action.instance)

        return html, Response.mime_type
      end
    end # Slim
  end # View
end # Innate
