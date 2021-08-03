module MultiStage
  class ProjectionMap
    attr_accessor :argv, :params, :io
    def initialize(output, argv = ARGV)
      @io = output
      @argv = argv
    end
    def run
      params = {:format => :txt}
      options = OptionParser.new do |opts|
      opts.program_name = "projection-map"
        opts.banner = <<"EOS"
NAME
    #{opts.program_name} - Convert imajeoletryfile to imageometryfile

SYNOPSIS AND USAGE
    #{opts.program_name} [options] IMAJEOLETRYFILE

DESCRIPTION
    Convert imajeoletryfile to imageometryfile using Affine matrix. 
    You need to have a pair of image file and image-info file. 
    The image-info file is created by JEOL JSM-7001F or JSM-8530F and 
    is also reffered as imajeoletryfile. The Affine matrix should be 
    specified by imageometryfile or inline expression.

EXAMPLE
    $ ls
    site-5-1.jpg site-5-1.txt
    $ cat site-5-1.txt
    $CM_MAG 150
    $CM_TITLE Site-5-1
    $CM_FULL_SIZE 1280 960
    $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
    $ vs-get-affine -f yaml > device.geo
    $ projection-map site-5-1.txt -a device.geo
    $ ls
    site-5-1.jpg site-5-1.txt site-5-1.geo device.geo
SEE ALSO
    vs-get-affine in [gem package -- vstool](https://gitlab.misasa.okayama-u.ac.jp/gems/vstool)
    vs_attach_image.m in [matlab script -- VisualSpots](http://multimed.misasa.okayama-u.ac.jp/repository/matlab)
    https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage
    https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage/blob/master/lib/multi_stage/projection_map.rb

IMPLEMENTATION
    Copyright (c) 2012-2021 Okayama University
  License GPLv3+: GNU GPL version 3 or later

HISTORY
    July 26, 2021: First commit.

OPTIONS
EOS
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          params[:verbose] = v
        end

        opts.on("-a", "--affine-file affine-file", "Specify Affine-matrix file") do |v|
          params[:affine_file] = v
        end

        opts.on("-m", "--affine-matrix a,b,c,d,e,f,g,h,i", Array, "Specify Affine matrix [[a,b,c],[d,e,f],[g,h,i]]") do |v|
          v.concat([0, 0, 1]) if v.length == 6
          if v.length != 9
            puts "incorrect number of arguments for Affine matrix"
              exit
            end
            v.map!{|vv| vv.to_f}
            params[:affine_matrix] = [ v[0..2], v[3..5], v[6..8] ]
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
            exit
        end
      end

      options.parse!(argv)

      unless argv.size == 1
        puts options.to_s
        exit
      end

      image_info_path = argv[0]

      if params[:affine_file]
        affine_array = YAML.load_file(params[:affine_file])
        affine_array = affine_array['affine_device2world'] if affine_array.is_a?(Hash)
        #affine = array_to_matrix(affine_array)
        affine = affine_array
      else
        affine = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      end

      if params[:affine_matrix]
        affine = params[:affine_matrix]
      end

      opts = {}
      #if params[:output_file]
      #  opts[:]
      #end      
      MultiStage::Image.from_sem_info(image_info_path, affine)
    end
  end
end  