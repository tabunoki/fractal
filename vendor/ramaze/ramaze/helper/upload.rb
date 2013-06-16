module Ramaze
  module Helper
    ##
    # Helper module for handling file uploads. File uploads are mostly handled
    # by Rack, but this helper adds some convenience methods for handling
    # and saving the uploaded files.
    #
    # @example
    #   class MyController < Ramaze::Controller
    #     # Use upload helper
    #     helper :upload
    #
    #     # This action will handle *all* uploaded files
    #     def handleupload1
    #       # Iterate over uploaded files and save them in the
    #       # '/uploads/myapp' directory
    #       get_uploaded_files.each_pair do |k, v|
    #         v.save(
    #           File.join('/uploads/myapp', v.filename),
    #           :allow_overwrite => true
    #         )
    #
    #         if v.saved?
    #           Ramaze::Log.info(
    #             "Saved uploaded file named #{k} to #{v.path}."
    #           )
    #         else
    #           Ramaze::Log.warn("Failed to save file named #{k}.")
    #         end
    #       end
    #     end
    #
    #     # This action will handle uploaded files beginning with 'up'
    #     def handleupload2
    #       # Iterate over uploaded files and save them in the
    #       # '/uploads/myapp' directory
    #       get_uploaded_files(/^up.*/).each_pair do |k, v|
    #         v.save(
    #           File.join('/uploads/myapp', v.filename),
    #           :allow_overwrite => true
    #         )
    #
    #         if v.saved?
    #           Ramaze::Log.info(
    #             "Saved uploaded file named #{k} to #{v.path}."
    #           )
    #         else
    #           Ramaze::Log.warn("Failed to save file named #{k}.")
    #         end
    #       end
    #     end
    #   end
    #
    # @author Lars Olsson
    # @since  04-08-2011
    #
    module Upload
      include Ramaze::Traited

      ##
      # This method will iterate through all request parameters and convert
      # those parameters which represents uploaded files to
      # Ramaze::Helper::Upload::UploadedFile objects. The matched parameters
      # will then be removed from the request parameter hash.
      #
      # Use this method if you want to decide whether to handle file uploads
      # in your action at runtime. For automatic handling, use
      # Ramaze::Helper::Upload::ClassMethods#handle_all_uploads or
      # Ramaze::Helper::Upload::ClassMethods#handle_uploads_for instead.
      #
      # @author Lars Olsson
      # @since  04-08-2011
      # @param  [Regexp] pattern If set, only those request parameters which
      #  has a name matching the Regexp will be checked for file uploads.
      # @return [Array] The uploaded files.
      # @see Ramaze::Helper::Upload::ClassMethods#handle_all_uploads
      # @see Ramaze::Helper::Upload::ClassMethods#handle_uploads_for
      #
      def get_uploaded_files(pattern = nil)
        uploaded_files = {}

        # Iterate over all request parameters
        request.params.each_pair do |k, v|
          # If we use a pattern, check that it matches
          if pattern.nil? or pattern =~ k
            # Rack supports request parameters with either a single value or
            # an array of values. To support both, we need to check if the
            # current parameter is an array or not.
            if v.is_a?(Array)
              # Got an array. Iterate through it and check for uploaded files
              file_indices = []

              v.each_with_index do |elem, idx|
                file_indices.push(idx) if is_uploaded_file?(elem)
              end

              # Convert found uploaded files to
              # Ramaze::Helper::Upload::UploadedFile objects
              file_elems = []

              file_indices.each do |fi|
                file_elems << Ramaze::Helper::Upload::UploadedFile.new(
                  v[fi][:filename],
                  v[fi][:type],
                  v[fi][:tempfile],
                  ancestral_trait[:upload_options] ||
                  Ramaze::Helper::Upload::ClassMethods.trait[
                    :default_upload_options
                  ]
                )
              end

              # Remove uploaded files from current request param
              file_indices.reverse_each do |fi|
                v.delete_at(fi)
              end

              # If the request parameter contained at least one file upload,
              # add upload(s) to the list of uploaded files
              uploaded_files[k] = file_elems unless file_elems.empty?

              # Delete parameter from request parameter array if it doesn't
              # contain any other elements.
              request.params.delete(k) if v.empty?
            else
              # Got a single value. Check if it is an uploaded file
              if is_uploaded_file?(v)
                # The current parameter represents an uploaded file.
                # Convert the parameter to a
                # Ramaze::Helper::Upload::UploadedFile object
                uploaded_files[k] = Ramaze::Helper::Upload::UploadedFile.new(
                  v[:filename],
                  v[:type],
                  v[:tempfile],
                  ancestral_trait[:upload_options] ||
                  Ramaze::Helper::Upload::ClassMethods.trait[
                    :default_upload_options
                  ]
                )

                # Delete parameter from request parameter array
                request.params.delete(k)
              end
            end
          end
        end

        # If at least one file upload matched, override the uploaded_files
        # method with a singleton method that returns the list of uploaded
        # files. Doing things this way allows us to store the list of uploaded
        # files without using an instance variable.
        unless uploaded_files.empty?
          @_ramaze_uploaded_files = uploaded_files

          # Save uploaded files if autosave is set to true
          if ancestral_trait[:upload_options] and
             ancestral_trait[:upload_options][:autosave]
            uploaded_files().each_value do |uf|
              uf.save
            end
          end
        end

        # The () is required, otherwise the name would collide with the variable
        # "uploaded_files".
        return uploaded_files()
      end

      ##
      # Adds some class method to the controller whenever the helper
      # is included.
      #
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      ##
      # Returns list of currently handled file uploads.
      #
      # Both single and array parameters are supported. If you give
      # your file upload fields the same name (for instance upload[]) Rack will
      # merge them into a single parameter. The upload helper will keep this
      # structure so that whenever the request parameter contains an array, the
      # uploaded_files method will also return an array of
      # Ramaze::Helper::Upload::UploadedFile objects for the same key.
      #
      # @return [Hash] Currently uploaded files. The keys in the hash
      #  corresponds to the names of the request parameters that contained file
      #  uploads and the values consist of Ramaze::Helper::Upload::UploadedFile
      #  objects.
      #
      def uploaded_files
        return @_ramaze_uploaded_files || {}
      end

      private

      # Returns whether +param+ is considered an uploaded file
      # A parameter is considered to be an uploaded file if it is
      # a hash and contains all parameters that Rack assigns to an
      # uploaded file
      #
      # @param [Hash] param A request parameter
      # @return [Boolean]
      def is_uploaded_file?(param)
        if param.respond_to?(:has_key?)
          [:filename, :type, :name, :tempfile, :head].each do |k|
            return false if !param.has_key?(k)
          end

          return true
        else
          return false
        end
      end

      # Helper class methods. Methods in this module will be available
      # in your controller *class* (not your controller instance).
      module ClassMethods
        include Ramaze::Traited

        # Default options for uploaded files. You can change these options
        # by using the uploads_options method
        trait :default_upload_options => {
          :allow_overwrite    => false,
          :autosave           => false,
          :default_upload_dir => nil,
          :unlink_tempfile    => false
        }.freeze

        ##
        # This method will activate automatic handling of uploaded files
        # for specified actions in the controller.
        #
        # @example
        #   class MyController < Ramaze::Controller
        #
        #     # Use upload helper
        #     helper :upload
        #
        #     # Handle all uploads for the foo and bar actions
        #     handle_uploads_for :foo, :bar
        #
        #     # Handle all uploads for the baz action and uploads beginning with
        #     # 'up' for the qux action
        #     handle_uploads_for :baz, [:qux, /^up.*/]
        #   end
        #
        # @param [Array] args An arbitrary long list of arguments with action
        #  names (and optionally patterns) that should handle file uploads
        #  automatically. Each argument can either be a symbol or a two-element
        #  array consisting of a symbol and a reqexp.
        # @see #handle_all_uploads
        # @see Ramaze::Helper::Upload#get_uploaded_files
        def handle_uploads_for(*args)
          args.each do |arg|
            if arg.respond_to?(:first) and arg.respond_to?(:last)
              before(arg.first.to_sym) do
                get_uploaded_files(arg.last)
              end
            else
              before(arg.to_sym) do
                get_uploaded_files
              end
            end
          end
        end

        ##
        # Sets options for file uploads in the controller.
        #
        # @example
        #   # This controller will handle all file uploads automatically.
        #   # All uploaded files are saved automatically in '/uploads/myapp'
        #   # and old files are overwritten.
        #   #
        #   class MyController < Ramaze::Controller
        #
        #     # Use upload helper
        #     helper :upload
        #
        #     handle_all_uploads
        #     upload_options :allow_overwrite => true,
        #                    :autosave => true,
        #                    :default_upload_dir => '/uploads/myapp',
        #                    :unlink_tempfile => true
        #   end
        #
        #   # This controller will handle all file uploads automatically.
        #   # All uploaded files are saved automatically, but the exact location
        #   # is depending on a session variable. Old files are overwritten.
        #   #
        #   class MyController2 < Ramaze::Controller
        #
        #     # Use upload helper
        #     helper :upload
        #
        #     # Proc to use for save directory calculation
        #     calculate_dir = lambda { File.join('/uploads', session['user']) }
        #
        #     handle_all_uploads
        #     upload_options :allow_overwrite => true,
        #                    :autosave => true,
        #                    :default_upload_dir => calculate_dir,
        #                    :unlink_tempfile => true
        #   end
        # @param [Hash] options Options controlling how file uploads
        #  are handled.
        # @option options [Boolean] :allow_overwrite If set to *true*, uploaded
        #  files are allowed to overwrite existing ones. This option is set to
        #  *false* by default.
        # @option options [Boolean] :autosave If set to *true*,
        #  Ramaze::Helper::Upload::UploadedFile#save will be called on all
        #  matched file uploads
        #  automatically. You can use this option to automatically save files
        #  at a preset location, but please note that you will need to set the
        #  :default_upload_dir (and possibly :allow_overwrite) options as well
        #  in order for this to work correctly. This option is set to *false*
        #  by default.
        # @option options [String|Proc] :default_upload_dir If set to a string
        #  (representing a path in the file system) this option will allow you
        #  to save uploaded files without specifying a path. If you intend to
        #  call Ramaze::Helper::Upload::UploadedFile#save with a path you don't
        #  need to set this option at all. If you need to delay the calculation
        #  of the directory, you can also set this option to a proc. The proc
        #  should accept zero arguments and return a string. This comes in handy
        #  when you want to use different directory paths for different users
        #  etc.  This option is set to *nil* by default.
        # @option options [Boolean] :unlink_tempfile If set to *true*, this
        #   option will automatically unlink the temporary file created by Rack
        #   immediately after Ramaze::Helper::Upload::UploadedFile#save is done
        #   saving the uploaded file. This is probably not needed in most cases,
        #   but if you don't want to expose your uploaded files in a shared
        #   tempdir longer than necessary this option might be for you. This
        #   option is set to *false* by default.
        # @see Ramaze::Helper::Upload::UploadedFile#initialize
        # @see Ramaze::Helper::Upload::UploadedFile#save
        #
        def upload_options(options)
          trait(
            :upload_options => Ramaze::Helper::Upload::ClassMethods.trait[
              :default_upload_options
            ].merge(options)
          )
        end
      end # ClassMethods

      ##
      # This class represents an uploaded file.
      #
      # @author Lars Olsson
      # @since  18-08-2011
      #
      class UploadedFile
        include Ramaze::Traited

        # Suggested file name
        # @return [String]
        attr_reader :filename

        # MIME-type
        # @return [String]
        attr_reader :type

        ##
        # Initializes a new Ramaze::Helper::Upload::UploadedFile object.
        #
        # @param [String] filename Suggested file name
        # @param [String] type MIME-type
        # @param [File] tempfile temporary file
        # @param [Hash] options Options for uploaded files. Options supported
        #  match those available to
        #  Ramaze::Helper::Upload::ClassMethods#upload_options
        # @return [Ramaze::Helper::Upload::UploadedFile] A new
        #  Ramaze::Helper::Upload::UploadedFile object
        # @see #save
        # @see Ramaze::Helper::Upload::ClassMethods#upload_options
        def initialize(filename, type, tempfile, options)
          @filename = File.basename(filename)
          @type     = type
          @tempfile = tempfile
          @realfile = nil

          trait :options => options
        end

        ##
        # Changes the suggested filename of this
        # Ramaze::Helper::Upload::UploadedFile.  +name+ should be a string
        # representing the filename (only the filename, not a complete path),
        # but if you provide a complete path this method it will try to identify
        # the filename and use that instead.
        #
        # @param [String] name The new suggested filename.
        #
        def filename=(name)
          @filename = File.basename(name)
        end

        ##
        # Returns the path of the Ramaze::Helper::Upload::UploadedFile object.
        # The method will always return *nil* before *save* has been called
        # on the Ramaze::Helper::Upload::UploadedFile object.
        #
        # @return [String|nil]
        #
        def path
          return self.saved? ? @realfile.path : nil
        end

        ##
        # Saves the Ramaze::Helper::Upload::UploadedFile.
        #
        # If +path+ is not set, the method checks whether there exists default
        # options for the path and tries to use that instead.
        #
        # If you need to override any options set in the controller (using
        # upload_options) you can set the corresponding option in +options+ to
        # override the behavior for this particular
        # Ramaze::Helper::Upload::UploadedFile object.
        #
        # @param [String] path Path where the
        #  Ramaze::Helper::Upload::UploadedFile will be saved
        # @param [Hash] options Options for uploaded files. Options supported
        #  match those available to
        #  Ramaze::Helper::Upload::ClassMethods#upload_options
        # @raise [StandardError] Will be raised if the save operation fails.
        # @see #initialize
        # @see Ramaze::Helper::Upload::ClassMethods#upload_options
        #
        def save(path = nil, options = {})
          # Merge options
          opts = trait[:options].merge(options)

          unless path
            # No path was provided, use info stored elsewhere to try to build
            # the path
            unless opts[:default_upload_dir]
              raise StandardError.new('Unable to save file, no dirname given')
            end

            unless @filename
              raise StandardError.new('Unable to save file, no filename given')
            end

            # Check to see if a proc or a string was used for the
            # default_upload_dir parameter. If it was a proc, call the proc and
            # use the result as the directory part of the path. If a string was
            # used, use the string directly as the directory part of the path.
            dn = opts[:default_upload_dir]

            if dn.respond_to?(:call)
              dn = dn.call
            end

            path = File.join(dn, @filename)
          end

          path = File.expand_path(path)

          # Abort if file altready exists and overwrites are not allowed
          if File.exists?(path) and !opts[:allow_overwrite]
            raise StandardError.new('Unable to overwrite existing file')
          end

          # Confirm that we can read source file
          unless File.readable?(@tempfile.path)
            raise StandardError.new('Unable to read temporary file')
          end

          # Confirm that we can write to the destination file
          unless (File.exists?(path) and File.writable?(path)) \
          or (File.exists?(File.dirname(path)) \
            and File.writable?(File.dirname(path)))
            raise StandardError.new(
              "Unable to save file to #{path}. Path is not writable"
            )
          end

          # If supported, use IO,copy_stream. If not, require fileutils
          # and use the same method from there
          if IO.respond_to?(:copy_stream)
            IO.copy_stream(@tempfile, path)
          else
            require 'fileutils'
            File.open(@tempfile.path, 'rb') do |src|
              File.open(path, 'wb') do |dest|
                FileUtils.copy_stream(src, dest)
              end
            end
          end

          # Update the realfile property, indicating that the file has been
          # saved
          @realfile = File.new(path)
          # But no need to keep it open
          @realfile.close

          # If the unlink_tempfile option is set to true, delete the temporary
          # file created by Rack
          unlink_tempfile if opts[:unlink_tempfile]
        end

        ##
        # Returns whether the Ramaze::Helper::Upload::UploadedFile has been
        # saved or not.
        #
        # @return [Boolean]
        #
        def saved?
          return !@realfile.nil?
        end

        ##
        # Deletes the temporary file associated with this
        # Ramaze::Helper::Upload::UploadedFile immediately.
        #
        def unlink_tempfile
          File.unlink(@tempfile.path)
          @tempfile = nil
        end
      end # UploadedFile
    end # Upload
  end # Helper
end # Ramaze
