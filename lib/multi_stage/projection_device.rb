module MultiStage
    class ProjectionDevice
      attr_accessor :argv, :params, :io
      def initialize(output, argv = ARGV)
        @io = output
        @argv = argv
      end
      def run
        params = {:magnification => 10.0, :stage_position => [0,0,10.0]}
        options = OptionParser.new do |opts|
        opts.program_name = "projection-device"
          opts.banner = <<"EOS"
  NAME
      #{opts.program_name} - Generate image-info file to project imagefile onto device space
  
  SYNOPSIS AND USAGE
      #{opts.program_name} [options] IMAGEFILE
  
  DESCRIPTION
      Generate image-info file to project imagefile onto device space.

      Usually the image-info file, that also is referred as
      imajeoletryfile, is created by JEOL JSM-7001F or JSM-8530F.
      When you need an image-info file for images obtained by machines
      besides JEOL JSM-7001F or JSM-8530F, call this program.
  
  EXAMPLE
      > ls
      cniso-mtx-c53-1s1@6065.jpg
      > projection-device cniso-mtx-c53-1s1@6065.jpg --magnification 10 --stage-position 2044,704,10200 --scan-rotaion 10.0
      > ls
      cniso-mtx-c53-1s1@6065.jpg cniso-mtx-c53-1s1@6065.txt
      > cat cniso-mtx-c53-1s1@6065
      $CM_MAG 10
      $CM_TITLE cniso-mtx-c53-1s1@6065
      $CM_FULL_SIZE 1280 960
      $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
      $$SM_SCAN_ROTATION 10.00
      > projection-device cniso-mtx-c53-1s1@6065.jpg --width 12000 --stage-position 2044,704,10200 --scan-rotaion 10.0
      > cat cniso-mtx-c53-1s1@6065.txt
      $CM_MAG 10
      $CM_TITLE cniso-mtx-c53-1s1@6065
      $CM_FULL_SIZE 1280 960
      $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
      $$SM_SCAN_ROTATION 10.00

  SEE ALSO
      projection-map in [gem package -- multi_stage](https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage)
      image-scalebar in [gem package -- scalebar](https://github.com/misasa/scalebar)
      https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage/blob/master/lib/multi_stage/projection_device.rb
  
  IMPLEMENTATION
      Copyright (c) 2012-2021 Okayama University
    License GPLv3+: GNU GPL version 3 or later
  
  HISTORY
      Aug 3, 2021: First commit.
  
  OPTIONS
EOS
          opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            params[:verbose] = v
          end
  
          opts.on("-x", "--magnification MAGNIFICATION", "Specify magnification") do |v|
            params[:magnification] = v
          end

          opts.on("-w", "--width WIDTH", "Specify width in micro meter") do |v|
            params[:width_in_um] = v
          end
  
          opts.on("-p", "--stage-position STAGE_X,STAGE_Y,STAGE_Z", Array, "Specify stage position [x,y,z] in micro meter") do |v|
            v.concat([10.0]) if v.length == 2
            if v.length != 3
              puts "incorrect number of arguments for stage position"
                exit
              end
              v.map!{|vv| vv.to_f/1000}
              params[:stage_position] = v
          end
  
          opts.on("-r", "--scan-rotation SCAN_ROTATION_IN_DEGREE", "Specify scan rotation in degree") do |v|
            params[:scan_rotation] = v
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
  
        image_path = argv[0]
        unless File.exists?(image_path)
            puts "#{image_path} does not exists!"
            exit
        end
        dirname = File.dirname(image_path)
        basename = File.basename(image_path,".*")
        txt_path = File.join(dirname, basename + ".txt")
        if File.exists?(txt_path)
            puts "#{txt_path} already exists! Please remove #{txt_path} first."
            exit
        end    

        if params[:width_in_um]
            params[:magnification] = 12.0 * 10 * 1000 / params[:width_in_um].to_f
        end
        opts = {}
        info = MultiStage::Image.generate_info(image_path, params)
        File.open(txt_path, mode = "w"){|f|
            info.each do |key,value|
                f.puts "#{key} #{value}"
            end
        }
      end
    end
  end  
