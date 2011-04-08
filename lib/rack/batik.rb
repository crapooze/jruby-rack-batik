
require 'rack'
require 'java'
require 'batik'
require 'stringio'


module Rack
  module Batik
    import org.apache.batik.transcoder.TranscodingHints
    import org.apache.batik.transcoder.image.JPEGTranscoder
    import org.apache.batik.transcoder.TranscoderInput
    import org.apache.batik.transcoder.TranscoderOutput
    module SVG
      # Transcoder is the mother class of the SVG to <raster format> middlewares,
      # do not use it directly, but use its subclasses.
      #
      # See Transcoder#call for how to implement your own transcoder subclass
      class Transcoder
        class << self
          # Sets the content type to use when transcoding 'image/svg+xml'
          def content_type(val=nil)
            @content_type = val if val
            @content_type
          end
        end

        def initialize(app)
          @app = app
        end

        # Modifies the response by:
        # - changing the content type from 'image/svg+xml' to the class's conten-type
        # - removing the content-length header if present
        # - replacing the SVG data body by the transcoder output
        #
        # At some point (see source) this method will call the #transcoder
        # of this middleware. This method should be overwritten in children classes
        # and return a Batik's transcoder object configured with the hints you want.
        #
        # If the conten-type from the previous response is not 'image/svg+xml',
        # this middleware just forwards to the lower layer of the application.
        def call(env)
          code, headers, body = @app.call(env)
          headers = headers.dup
          if (code == 200) and (headers['Content-Type'] == 'image/svg+xml')
            headers.delete('Content-Length')
            headers['Content-Type'] = self.class.content_type

            in_io = StringIO.new
            body.each do |chunk|
              in_io << chunk
            end
            in_io.rewind
            out_io = StringIO.new('','w+b')

            input = TranscoderInput.java_class.constructor(java.io.InputStream).
              new_instance(in_io.to_inputstream)
            output = TranscoderOutput.java_class.constructor(java.io.OutputStream).
              new_instance(out_io.to_outputstream)


            transcoder(env).transcode(input, output)

            out_io.flush
            out_io.rewind
            [code, headers, out_io]
          else
            [code, headers, body]
          end
        end

        # Placeholder to be overwritten in subclasses
        def transcoder(env)
          raise NotImplementedError
        end
      end

      class JPEG < Transcoder
        content_type  'image/jpeg'

        def quality(env)
          0.8
        end

        def transcoder(env)
          transcoder = JPEGTranscoder.new
          transcoder.java_send(:addTranscodingHint, 
                               [TranscodingHints::Key, java.lang.Object],
                               JPEGTranscoder::KEY_QUALITY, 
                               quality(env).to_java(java.lang.Float))
          transcoder
        end
      end
    end
  end
end
