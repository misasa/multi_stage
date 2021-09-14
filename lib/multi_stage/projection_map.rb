module MultiStage
  class ProjectionMap
    attr_accessor :argv, :params, :io
    def initialize(output, argv = ARGV)
      @io = output
      @argv = argv
    end
    def run
      params = {:format => :txt, :stage_origin => :ru}
      options = OptionParser.new do |opts|
      opts.program_name = "projection-map"
        opts.banner = <<"EOS"
NAME
    #{opts.program_name} - Generate imageometryfile to project imagefile onto VS space

SYNOPSIS AND USAGE
    #{opts.program_name} [options] IMAJEOLETRYFILE

DESCRIPTION
    Generate imageometryfile to project imagefile onto VS space.

    You need to have a pair of image file and image-info file, and
    device-to-vs Affine matrix.  The image-info file is created by
    JEOL JSM-7001F or JSM-8530F and is also reffered as
    imajeoletryfile.  The Affine matrix should be obtained from
    VisualStage 2007.  The Affine matrix should be fed
    into #{opts.program_name} by imageometryfile or inline expression.

    Create image-info file manually when necessary using utility
    projection-device.
    
    On projection of image obtained by SIMS, specify --stage-origin
    explicitly.
    
    |--------+----------------|
    | device | --stage-origin |
    |--------+----------------|
    | SIMS   | lu             |
    | SEM    | ru (default)   |
    |--------+----------------|

EXAMPLE
    > ls
    cniso-mtx-c53-1s1@6065.jpg cniso-mtx-c53-1s1@6065.txt
    > cat cniso-mtx-c53-1s1@6065.txt
    $CM_MAG 150
    $CM_TITLE cniso-mtx-c53-1s1@6065
    $CM_FULL_SIZE 1280 960
    $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
    $$SM_SCAN_ROTATION 10.00
    > vs-get-affine -f yaml > stage-of-VS1280@surface-mnt-C0053-1-s1.geo
    > projection-map cniso-mtx-c53-1s1@6065.txt -a stage-of-VS1280@surface-mnt-C0053-1-s1.geo --stage-origin lu
    $ ls
    cniso-mtx-c53-1s1@6065.jpg cniso-mtx-c53-1s1@6065.txt cniso-mtx-c53-1s1@6065.geo stage-of-VS1280@surface-mnt-C0053-1-s1.geo
    > orochi-upload --surface_id=${SURFACEID} --layer=${LAYERNAME} cniso-mtx-c53-1s1@6065.jpg

SEE ALSO
    projection-device in [gem package -- multi_stage](https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage)
    orochi-upload in [gem package -- orochi-for-medusa](https://github.com/misasa/orochi-for-medusa)
    vs-get-affine in [gem package -- vstool](https://gitlab.misasa.okayama-u.ac.jp/gems/vstool)
    vs-attach-image in [gem package -- vstool](https://gitlab.misasa.okayama-u.ac.jp/gems/vstool)
    vs_attach_image.m in [matlab script -- VisualSpots](http://multimed.misasa.okayama-u.ac.jp/repository/matlab)
    https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage/blob/master/lib/multi_stage/projection_map.rb

IMPLEMENTATION
    Copyright (c) 2012-2021 Okayama University
  License GPLv3+: GNU GPL version 3 or later

HISTORY
    Aug 3, 2021: Support $$SCAN_ROTATION
    July 26, 2021: First commit.

OPTIONS
EOS
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          params[:verbose] = v
        end

        opts.on("-a", "--affine-file affine-file", "Specify Affine-matrix file") do |v|
          params[:affine_file] = v
        end

        opts.on("-m", "--affine-matrix a,b,c,d,e,f,g,h,i", Array, "Specify Affine-matrix elements [a,b,c; d,e,f; g,h,i]") do |v|
          v.concat([0, 0, 1]) if v.length == 6
          if v.length != 9
            puts "incorrect number of arguments for Affine matrix"
              exit
            end
            v.map!{|vv| vv.to_f}
            params[:affine_matrix] = [ v[0..2], v[3..5], v[6..8] ]
        end

        opts.on("-r", "--stage-origin VALUE", [:lu, :ru, :rb, :lb], "Specify stage origin: ld, rd, ru, or lu [default: #{params[:stage_origin]}]") do |v|
          params[:stage_origin] = v
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
      opts[:origin] = params[:stage_origin]
      MultiStage::Image.from_sem_info(image_info_path, affine, opts)
    end
  end
end  
