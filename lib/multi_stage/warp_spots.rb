require 'optparse'
require 'matrix'
require 'yaml'
require 'dimensions'

module Dimensions
  def self.length(filename)
    self.dimensions(filename).max
  end

  def self.normalized_dimensions(filename)
    d = self.dimensions(filename)
    l = self.length(filename)
    [d[0]/l.to_f * 100, d[1]/l.to_f * 100]
  end
end

class Array
  def in_groups_of(number, fill_with = nil)
    if fill_with == false
      collection = self
    else
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - size % number) % number
      collection = dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      groups = []
      collection.each_slice(number) { |group| groups << group }
      groups
    end
  end
end

module MultiStage
  class WarpSpots
    attr_accessor :argv, :params, :io
    def initialize(output, argv = ARGV)
      @io = output
      #cmd_options(argv)
      @argv = argv
    end

    def generate_point_data(path)
      basename = File.basename(path, ".*")
      ext = File.extname(path)
      lines = []
      File.open(path) do |f|
        while line = f.gets
          lines << line.chomp
        end
      end
      head = lines.shift.split("\t")

      point_data = []
      lines.each do |line|
        vals = line.split("\t")
        h = Hash.new
        vals.each_with_index{|val,index| h[head[index]] = val}
        h["X-Locate"] = h["X-Locate"].to_f
        h["Y-Locate"] = h["Y-Locate"].to_f
        point_data << h
      end
      return point_data
    end

    def tex_escape(txt)
      return unless txt
      txt = txt.gsub('_','\_')
      txt = txt.gsub(/#/,'\#')
      return txt
    end

    def line_items(point)
      [point["Class"],point["Name"],sprintf("%.3f", point["X-Locate"]),sprintf("%.3f", point["Y-Locate"]),point["Data"]]
    end

    def array_to_matrix(array)
      m = Matrix[array[0],array[1],array[2]]
      return m
    end

    def transform_points(affine, points)
      num_points = points.size
      src_points = Matrix[points.map{|p| p[0]}, points.map{|p| p[1]}, Array.new(points.size, 1.0)]
      warped_points = (affine * src_points).to_a

      xt = warped_points[0]
      yt = warped_points[1]
      dst_points = []
      num_points.times do |i|
        dst_points << [xt[i], yt[i]]
      end
      return dst_points
    end

    def transform_length(affine, l)
      # affine = Matrix[affine_array[0],affine_array[1],affine_array[2]]
      # src_points = Matrix[[0, l], [0, 0], Array.new(2, 1.0)]
      src_points = [[0,0],[l,0]]
      # warped_points = (affine * src_points).to_a
      # p warped_points
      # xt = warped_points[0]
      # yt = warped_points[1]
      dst_points = transform_points(affine, src_points)
      return Math::sqrt((dst_points[0][0] - dst_points[1][0]) ** 2 + (dst_points[0][1] - dst_points[1][1]) ** 2)
    end


    def run
      params = {:format => :txt}
      options = OptionParser.new do |opts|
      opts.program_name = "spots-warp"
        opts.banner = <<"EOS"
NAME
    #{opts.program_name} - Project coordinate to other space

SYNOPSIS AND USAGE
    #{opts.program_name} [options] stagelist.txt

DESCRIPTION
    Project coordinate to other space using Affine matrix.
    The Affine matrix should be specified by imageometryfile or inline
    expression.

    As of December 12, 2018, #{opts.program_name} accepts `stagelist.txt'
    format that is format of a file exported from VisualStage 2007.  
    With identity matrix, this serves as a format converter.

    This is useful to convert between stage coordinate of certain
    device and global coordinate in VisualStage 2007.

    When image is specified, this program assumes that there is
    imageometryfile with it.

EXAMPLE
    $ vs-get-affine > stagelist@1270.geo
    $ spots-warp stagelist@1270.txt -o stagelist.txt -a stagelist@1270.geo

    To import spots described in relative corrdinates created by
    `spots.m' using imageometry file by `vs_attach_image.m', follow an
    expamle shown blow.  Create `site5-1.xy-on-image.txt' manually
    using xy-on-image corrdinates that are stored in `site-5-1.pml~'.
    Then create `site-5-1.vs.txt' to be imported to VisualStage 2007.

    $ ls
    site-5-1.jpg site-5-1.geo site-5-1.pml~ site5-1.xy-on-image.txt
    $ cat site-5-1.xy-on-image.txt
    Class Name  X-Locate  Y-Locate  Data
    0 site-5-1 Ol 16.796875 19.140625 
    0 site-5-1 Aug  -15.859375  4.06249999999999  
    0 site-5-1 Lpx  6.64062499999999  -13.671875  
    0 site-5-1 graphite 4.37499999999999  -6.09375000000001 
    $ spots-warp site-5-1.xy-on-image.txt -a site-5-1.geo > site-5-1.vs.txt

SEE ALSO
    vs-warp-spots-1270 in [gem package -- vstool](https://gitlab.misasa.okayama-u.ac.jp/gems/vstool)
    vs-get-affine in [gem package -- vstool](https://gitlab.misasa.okayama-u.ac.jp/gems/vstool)
    image-get-affine in [python package -- image_mosaic](https://github.com/misasa/image_mosaic)
    spots.m in [matlab script -- VisualSpots](http://multimed.misasa.okayama-u.ac.jp/repository/matlab)
    vs_attach_image.m in [matlab script -- VisualSpots](http://multimed.misasa.okayama-u.ac.jp/repository/matlab)
    vs2cha
    cha2vs
    https://gitlab.misasa.okayama-u.ac.jp/gems/multi_stage

IMPLEMENTATION
    Copyright (c) 2012,2018 Okayama University
  License GPLv3+: GNU GPL version 3 or later

HISTORY
    December 12, 2018: Drop support for Cameca
    March 30, 2018: Documantation corrected.
    April 10, 2015: Rename warp_spots as #{File.basename($0, '.*')}.
    May 25, 2015: Drop support for stagelist.spot

OPTIONS
EOS
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          params[:verbose] = v
        end

        opts.on("-i", "--inverse", "Use inverse Affine matrix") do |v|
          params[:inverse] = v
        end

        opts.on("-g", "--image-file image-file", "Specify image file") do |v|
          params[:image_file] = v
        end

        opts.on("-a", "--affine-file affine-file", "Specify Affine-matrix file") do |v|
          params[:affine_file] = v
        end

        opts.on("-m", "--affine-matrix a,b,c,d,e,f,g,h,i", Array, "Specify Affine matrix [a,b,c; d,e,f; g,h,i]") do |v|
          v.concat([0, 0, 1]) if v.length == 6
          if v.length != 9
            puts "incorrect number of arguments for Affine matrix"
              exit
            end
            v.map!{|vv| vv.to_f}
            params[:affine_matrix] = Matrix[ v[0..2], v[3..5], v[6..8] ]
        end

        opts.on("-f", "--format FORMAT", [:txt, :csv, :org, :tex, :yaml],
                    "Format of text onto standard output (txt, csv, yaml, org, tex)") do |t|
          params[:format] = t
        end

        opts.on("-o", "--output-file output-file", "Name of output file with exension that should be one of (.txt, .csv, .yaml, .org, .tex)") do |v|
          params[:output_file] = v
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

      points_path = argv[0]
      timestamp = Time.now.strftime("%d-%b-%Y %H:%M:%S")

      if params[:output_file]
        basename = File.basename(params[:output_file], ".*")
        ext = File.extname(params[:output_file])
        params[:format] = ext.sub(/\./,"").to_sym if ext
          #chain_file = basename + '.cha'
        if params[:format] == :tex && !params[:image_file]
          candidates = Dir.glob(basename + ".{jpg,jpeg,JPG,JPEG}")
          params[:image_file] = candidates[0] if candidates.size > 0
        end
        io = File.open(params[:output_file], "w")
      else
        io = STDOUT
      end


      if params[:image_file] && !params[:affine_file]
        dirname = File.dirname(params[:image_file])
          basename = File.basename(params[:image_file], ".*")
          params[:affine_file] = File.join(dirname, basename + '.yaml')
          params[:inverse] = true unless params[:inverse]
      end

      if params[:affine_file]
        affine_array = YAML.load_file(params[:affine_file])
        affine_array = affine_array['affine_xy2vs'] if affine_array.is_a?(Hash)
        affine = array_to_matrix(affine_array)
      #  affine = Matrix[affine_array[0],affine_array[1],affine_array[2]]
      else
        affine = Matrix[[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      end

      if params[:affine_matrix]
        affine = params[:affine_matrix]
      end

      if params[:inverse]
        affine = affine.inv
      end

      point_data = generate_point_data(points_path)

      #lines = []
      head = %w(Class Name X-Locate Y-Locate Data)
      # File.open(points_path) do |f|
      #   while line = f.gets
      #     lines << line.chomp
      #   end
      # end
      # head = lines.shift.split("\t")
      #
      # point_data = []
      # lines.each do |line|
      #   vals = line.split("\t")
      #   h = Hash.new
      #   vals.each_with_index{|val,index| h[head[index]] = val}
      #   h["X-Locate"] = h["X-Locate"].to_f
      #   h["Y-Locate"] = h["Y-Locate"].to_f
      #   point_data << h
      # end

      dst_points = transform_points(affine, point_data.map{|p| [p["X-Locate"], p["Y-Locate"]]})

      original_data = []
      point_data.each_with_index do |point, index|
        original_data << point.dup
        point["X-Locate"] = dst_points[index][0]
        point["Y-Locate"] = dst_points[index][1]
      end
      #transform_points(affine, )

      case params[:format]
      when :txt
        io.puts head.join("\t")
        point_data.each do |point|
          io.puts line_items(point).join("\t")
        end
      when :csv
        io.puts head.join(",")
        point_data.each do |point|
          io.puts line_items(point).join(",")
        end
      when :org
        io.puts "|" + head.join("|") + "|"
        point_data.each do |point|
          io.puts "|" + line_items(point).join("|") + "|"
        end
      when :spots
        unless params[:image_file]
          puts "Specify image-file with -g option"
          exit
        end
        normalized_dimensions = Dimensions.normalized_dimensions(params[:image_file])
        length = Dimensions.length(params[:image_file])
        point_data.each_with_index do |point, idx|
          point["X-Locate"] += normalized_dimensions[0]/2.0
          point["Y-Locate"] = normalized_dimensions[1] - (normalized_dimensions[1]/2.0 - point["Y-Locate"])
          io.puts sprintf("%s\t%.3f\t%.3f\t%.3f\t%.3f\t\%.3f",point["Name"], point["X-Locate"], point["Y-Locate"], 0.3, 0.3, 0.0)
        end

      when :tex
        unless params[:image_file]
          puts "Specify image-file with -g option"
          exit
        end
        normalized_dimensions = Dimensions.normalized_dimensions(params[:image_file])
        length = Dimensions.length(params[:image_file])
        #affine_ij2vs = array_to_matrix(YAML.load_file(params[:affine_file])['affine_ij2vs'])
        image = MultiStage::Image.load(params[:affine_file])
        affine_ij2vs = array_to_matrix(image.affine(:pixs2world))
        affine_vs2ij = affine_ij2vs.inv
        width_on_stage = transform_length(affine_ij2vs, Dimensions.width(params[:image_file]))
        scale_length_on_stage = 10 ** (Math::log10(width_on_stage).round - 1)
        scale_length_on_image = transform_length(affine_vs2ij, scale_length_on_stage).round
      #  io.puts head.join("\t")

        io.puts '%----------------------------------'
        io.puts '%\\documentclass[12pt]{article}'
        io.puts '%\\usepackage[margin=0.5in,a4paper]{geometry}'
        io.puts '%\\usepackage{color,pmlatex}'
        io.puts '%\\usepackage{pict2e}'
        io.puts '%\\begin{document}'
        io.puts '%%'
        io.puts '%%Spots coordinates for \\LaTeX overpic environment'
        io.puts '%%This is generated by vs2spots.py on ' + timestamp
        io.puts '%% affine_tex2vs = [1 0 0;0 1 0; 0 0 1];'
        io.puts '\\begin{figure}[htbp]'
        io.puts ' \\centering'
        io.puts ' %%'
        io.puts sprintf(' \\begin{overpic}[width=\\textwidth]{%s}', params[:image_file])
        io.puts sprintf('  \\put(03.0,70.0){\\colorbox{white}{\\bf (a) \\data{%s}}}', basename)
        io.puts '  \\color{red}'

        point_data.each_with_index do |point, idx|
          #point["X-Locate"] += normalized_dimensions[0]/2.0
          #point["Y-Locate"] -= normalized_dimensions[1]/2.0
          point["X-Locate"] += normalized_dimensions[0]/2.0
          point["Y-Locate"] = normalized_dimensions[1] - (normalized_dimensions[1]/2.0 - point["Y-Locate"])

          original = original_data[idx]
          image_coord = sprintf("\\put(%.1f,%.1f){\\footnotesize \\circle{0.7} \\onspot \\hrefdream{%s}{%s}}", point["X-Locate"], point["Y-Locate"], tex_escape(point["Data"]), tex_escape(point["Name"]))
          world_coord = sprintf("\\vs(%.1f, %.1f)", original["X-Locate"], original["Y-Locate"])
          io.puts '  ' + image_coord + " % " + world_coord
        end
        io.puts ' %%' + sprintf("scale %.0f micro meter", scale_length_on_stage )
        io.puts sprintf(" \\put(1,1){\\line(1,0){%.1f}}", scale_length_on_image/length.to_f*100 )
        io.puts ' \\end{overpic}'
        io.puts ' %%'
        io.puts sprintf(' \\caption{An image of \\data{%s} with analyzed spots on %s.}', basename, timestamp)
        io.puts sprintf(' \\label{spots:%s at %s}', basename, timestamp)
        io.puts '\\end{figure}'
        io.puts '%\\end{document}'
        io.puts '%----------------------------------'
      when :yaml
        io.puts YAML.dump(point_data)
      else
        raise "Invalid format #{params[:format]}"
      end
    end

  end
end
