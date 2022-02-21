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
    #{opts.program_name} [options] IMAGEFILE

DESCRIPTION
    Generate imageometryfile to project imagefile onto VS space.

    You need to have a pair of image file and image-info file, and
    device-to-vs Affine matrix (stageometry).  The image-info file
    is created by JEOL JSM-7001F or JSM-8530F and is also reffered as
    imajeoletryfile.  The Affine matrix (stageometry) should be obtained from
    VisualStage 2007.  The Affine matrix (stageometry) should be fed
    into #{opts.program_name} by imageometryfile or inline expression.

    Create image-info file manually when necessary using utility
    `projection-device'.
    
    On projection of image obtained by SIMS, specify `--stage-origin ld'
    explicitly.
    
    |--------+----------------|
    | device | --stage-origin |
    |--------+----------------|
    | SEM    | ru (default)   |
    | SIMS   | ld             |
    |--------+----------------|
    
    When you locate an image obtained by SEM onto a new surface (without
    alignment), call this program with stageometry [-1,0,0;0,-1,0;0,0,1].

    This program currently supports GIF, PNG, JPEG and TIFF images.

EXAMPLE
    SIMS> ls
    cniso-mtx-c53-1s1@6065.jpg cniso-mtx-c53-1s1@6065.txt
    SIMS> cat cniso-mtx-c53-1s1@6065.txt
    $CM_MAG 150
    $CM_TITLE cniso-mtx-c53-1s1@6065
    $CM_FULL_SIZE 1280 960
    $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
    $$SM_SCAN_ROTATION 10.00
    SIMS> vs-get-affine -f yaml > stage-of-VS1280@surface-mnt-C0053-1-s1.geo
    SIMS> projection-map cniso-mtx-c53-1s1@6065.jpg -a stage-of-VS1280@surface-mnt-C0053-1-s1.geo --stage-origin ld
    $ ls
    cniso-mtx-c53-1s1@6065.jpg cniso-mtx-c53-1s1@6065.txt cniso-mtx-c53-1s1@6065.geo stage-of-VS1280@surface-mnt-C0053-1-s1.geo
    SIMS> orochi-upload --surface_id=${SURFACEID} --layer=${LAYERNAME} --refresh-tile cniso-mtx-c53-1s1@6065.jpg
    
    SEM> projection-map -m -1,0,0,0,-1,0,0,0,1 cniso-mtx-c53-1s1@6065.jpg

SEE ALSO
    projection-device in [gem package -- multi_stage](https://github.com/misasa/multi_stage)
    orochi-upload in [gem package -- orochi-for-medusa](https://github.com/misasa/orochi-for-medusa)
    vs-get-affine in [gem package -- vstool](https://github.com/misasa/vstool)
    vs-attach-image in [gem package -- vstool](https://github.com/misasa/vstool)
    vs_attach_image.m in [matlab script -- VisualSpots](http://multimed.misasa.okayama-u.ac.jp/repository/matlab)
    https://github.com/misasa/multi_stage/blob/master/lib/multi_stage/projection_map.rb

IMPLEMENTATION
    Copyright (c) 2012-2021 Okayama University
  License GPLv3+: GNU GPL version 3 or later

HISTORY
    Sep 14, 2021: Supprt stage-origin option
    Aug 3, 2021: Support $$SCAN_ROTATION
    July 26, 2021: First commit.

OPTIONS
EOS
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          params[:verbose] = v
        end

        opts.on("-a", "--affine-file affine-file", "Specify stageometry as Affine-matrix file") do |v|
          params[:affine_file] = v
        end

        opts.on("-m", "--affine-matrix a,b,c,d,e,f,g,h,i", Array, "Specify stageometry as Affine-matrix elements [a,b,c; d,e,f; g,h,i]") do |v|
          v.concat([0, 0, 1]) if v.length == 6
          if v.length != 9
            puts "incorrect number of arguments for Affine matrix"
              exit
            end
            v.map!{|vv| vv.to_f}
            params[:affine_matrix] = [ v[0..2], v[3..5], v[6..8] ]
        end

        opts.on("-r", "--stage-origin VALUE", [:lu, :ru, :rd, :ld], "Specify stage origin: ld, rd, ru, or lu [default: #{params[:stage_origin]}]") do |v|
          params[:stage_origin] = v
        end

        opts.on("--[no-]dump-affine-in-string", "Dump affine matrix in string") do |v|
          params[:dump_affine_in_string] = v
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

      if File.extname(argv[0]) == ".txt"
        raise "Specify imagefile insted of imajeoletryfile"
      end
      image_path = argv[0]
      dir_name = File.dirname(image_path)
      base_name = File.basename(image_path, ".*")
      image_info_path = File.join(dir_name, base_name + ".txt")
      
      if params[:affine_file]
        affine_array = YAML.load_file(params[:affine_file])
        if affine_array.is_a?(Hash)
          if affine_array.has_key?('affine_device2world')
            affine_array = affine_array['affine_device2world'] 
          elsif affine_array.has_key?('stageometry')
            affine_array = affine_array['stageometry'] 
          end
        end
        #affine = array_to_matrix(affine_array)
        if affine_array.is_a?(String)
          str = affine_array
          str = str.gsub(/\[/,"").gsub(/\]/,"").gsub(/\;/,",").gsub(/\s+/,"")
          tokens = str.split(',')
          vals = tokens.map{|token| token.to_f}
          vals.concat([0,0,1]) if vals.size == 6
          if vals.size == 9
            affine_array = [vals[0..2],vals[3..5],vals[6..8]]
          end
        end
        affine = affine_array
      else
        affine = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      end

      if params[:affine_matrix]
        affine = params[:affine_matrix]
      end

      opts = {}
      opts[:origin] = params[:stage_origin]
      opts[:affine_in_string] = true
      opts[:image_path] = image_path
      MultiStage::Image.from_sem_info(image_info_path, affine, opts)
    end
  end
end  
