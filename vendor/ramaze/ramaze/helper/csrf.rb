require 'securerandom'
require 'digest'

module Ramaze
  module Helper
    ##
    # A relatively basic yet useful helper that can be used to protect your
    # application from CSRF attacks/exploits. Note that this helper merely
    # generates the required data, and provides several methods. You still need
    # to manually add the token to each form.
    #
    # The reason for this is because this is quite simple. Ramaze is meant as a
    # framework that works with any given helper, ORM, template engine and so
    # on. If we were to automatically load this helper and include (a perhaps
    # more advanced) CSRF system that would mean that every form helper,
    # official or third-party, would have to support that specific system.
    # However, there's no need to panic as it's very easy to setup a basic anti
    # CSRF system.
    #
    # ## Usage
    #
    # In order to enable CSRF protection we need to do two things. Load the
    # helper and create a before_all block in a controller. Take a look at the
    # following code:
    #
    #     class BaseController < Ramaze::Controller
    #       before_all do
    #         puts "Hello, before_all!"
    #       end
    #     end
    #
    # This would output "Hello, before_all!" to the console upon each request.
    # Not very useful but it does show what the before_all block can do. On to
    # actual CSRF related code!
    #
    #     class BaseController < Ramaze::Controller
    #       before_all do
    #         csrf_protection :save do
    #           # ....
    #         end
    #       end
    #     end
    #
    # This example introduces an extra block that validates the current
    # request. Whenever a user requests a controller that either extends
    # BaseController or has it's own before_all block Ramaze will check if the
    # current request data contains a CSRF token. Of course an if/end isn't
    # very useful if it doesn't do anything, let's add some code.
    #
    #     class BaseController < Ramaze::Controller
    #       before_all do
    #         csrf_protection :save do
    #           puts "Hello, unsafe data!"
    #         end
    #       end
    #     end
    #
    # The code above checks if the current method is "save" (or any other of
    # the provided methods) and checks if an CSRF token is supplied if the
    # method matches. Protected methods require a token in ALL HTTP requests
    # (GET, POST, etc). While this may seem weird since GET is generally used
    # for safe actions it actually makes sense. Ramaze stores both the POST and
    # GET parameters in the request.params hash. While this makes it easy to
    # work with POST/GET data this also makes it easier to spoof POST requests
    # using a GET request, thus this helper protects ALL request methods.
    #
    # If you're a lazy person you can copy-paste the example below and adapt it
    # to your needs.
    #
    #     class BaseController < Ramaze::Controller
    #       before_all do
    #         csrf_protection :save do
    #           respond("The supplied CSRF token is invalid.", 401)
    #         end
    #       end
    #     end
    #
    module CSRF
      include Innate::Optioned

      options.dsl do
        o 'The name of the token field', :field_name, 'csrf_token'
      end

      ##
      # Method that can be used to protect the specified methods against CSRF
      # exploits. Each protected method will require the token to be stored in
      # a field called "csrf_token". This method will then validate that token
      # against the current token in the session.
      #
      # @param [Array] methods Array of method names that should be checked.
      # @param [Proc] block Block that will be executed if the token is
      #  invalid.
      # @example
      #  # Protect "create" and "save" against CSRF exploits
      #  before_all do
      #    csrf_protection :create, :save do
      #      respond("GET TO DA CHOPPA!", 401)
      #    end
      #  end
      #
      def csrf_protection(*methods, &block)
        if methods.include?(action.name) \
        or methods.include?(action.name.to_sym)
          unless validate_csrf_token(request.params[CSRF.options.field_name])
            yield
          end
        end
      end

      ##
      # Generate a new token and create the session array that will be used to
      # validate the client.
      #
      # Note that this method will be automatically called if no CSRF token
      # exists.
      #
      # @param [Hash] args Additional arguments that can be set such as the
      #  TTL.
      #
      def generate_csrf_token(args = {})
        random = SecureRandom.random_bytes(512)
        time   = Time.now.to_f
        token  = Digest::SHA512.hexdigest(random + time.to_s)

        # Time to store all the data we want to check later.
        session[:_csrf] = {
          :token => token,
          :ip    => request.ip,
          :agent => request.env['HTTP_USER_AGENT'],
          :host  => request.host
        }

        return
      end

      ##
      # Retrieves the current value of the CSRF token.
      #
      # @return [String] The current CSRF token.
      # @example
      #  form(@data, :method => :post) do |f|
      #    f.input_hidden :csrf_token, get_csrf_token()
      #  end
      #
      def get_csrf_token
        if !session[:_csrf] || !self.validate_csrf_token(session[:_csrf][:token])
          self.generate_csrf_token
        end

        return session[:_csrf][:token]
      end

      ##
      # Validates the request based on the current session date stored in
      # _csrf.
      #
      # @param  [String] input_token The CSRF token to validate.
      # @return [TrueClass|FalseClass]
      # @example
      #  before_all do
      #    if validate_csrf_token(request.params['csrf_token']) != true
      #      respond("Invalid CSRF token", 401)
      #    end
      #  end
      #
      def validate_csrf_token(input_token)
        # Check if the CSRF data has been generated and generate it if this
        # hasn't been done already (usually on the first request).
        if !session[:_csrf] or session[:_csrf].empty?
          self.generate_csrf_token
        end

        _csrf = session[:_csrf]

        valid = session[:_csrf][:token] == input_token &&
          _csrf[:host]  == request.host &&
          _csrf[:ip]    == request.ip &&
          _csrf[:agent] == request.env['HTTP_USER_AGENT']

        if valid
          generate_csrf_token

          return true
        else
          return false
        end
      end
    end # CSRF
  end # Helper
end # Ramaze
