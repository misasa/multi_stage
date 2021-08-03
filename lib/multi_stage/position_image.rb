module MultiStage
    class PositionImage
      attr_accessor :argv, :params, :io
      def initialize(output, argv = ARGV)
        @io = output
        @argv = argv
      end
      def run
        params = {:magnification => 10.0, :stage_position => [0,0,10.0]}
        options = OptionParser.new do |opts|
        opts.program_name = "position-image"
          opts.banner = <<"EOS"
  NAME
      #{opts.program_name} - Generate imajeoletryfile
  
  SYNOPSIS AND USAGE
      #{opts.program_name} [options] IMAGEFILE
  
  DESCRIPTION
      Generate image-info file. 
  
  EXAMPLE
      > ls
      site-5-1.jpg
      > position-image site-5-1.jpg --magnification 10 --stage-position 2044,704,10200
      > ls
      site-5-1.jpg site-5-1.txt
      > cat site-5-1.txt
      $CM_MAG 10
      $CM_TITLE Site-5-1
      $CM_FULL_SIZE 1280 960
      $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
      > position-image site-5-1.jpg --width 12000 --stage-position 2044,704,10200
      > cat site-5-1.txt
      $CM_MAG 10
      $CM_TITLE Site-5-1
      $CM_FULL_SIZE 1280 960
      $CM_STAGE_POS 2.044 0.704 10.2 11.0 0.0 0
  SEE ALSO
      vs-get-affine in [gem package -- vstool](https://gitlab.misasa.okayama-u.ac.jp/gems/vstool)
      vs_attach_image.m in [matlab script -- VisualSpots](http://multimed.misasa.okayama-u.ac.jp/repository/matlab)
      https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage
      https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage/blob/master/lib/multi_stage/projection_map.rb
  
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