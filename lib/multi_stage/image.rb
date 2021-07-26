require 'dimensions'
require 'yaml'
require 'opencvtool'

module MultiStage
  class Image
  #  attr_accessor :title, :scan_rotation, :pixels_per_um, :width_in_pix, :height_in_pix, :width_in_um, :height_in_um, :magnification, :stage_position, :stage_x_in_um, :stage_y_in_um, :affine
    attr_accessor :image_path, :info_path, :image_dimensions
    attr_accessor :name, :size, :locate, :center, :pixs
  #  attr_accessor :stage_origin
    attr_accessor :opencvtool

    def self.verbose
      @@verbose ||= false
    end

    def verbose
      self.class.verbose
    end

    def self.opencvtool
      @@opencvtool ||= OpenCvTool::OpenCvTool.new(:verbose => verbose)
    end

    def opencvtool
      self.class.opencvtool
    end

    def self.corners_on_stage(opts = {})
      center = opts[:center]
      size = opts[:size]
      origin = opts[:origin] || "ru"

      ranges = []
      2.times do |i|
        range = []
        range << center[i] - size[i]/2.0
        range << center[i] + size[i]/2.0
        ranges << range
      end

      x_min, x_max = ranges[0]
      y_min, y_max = ranges[1]

      case origin
      when "ld"
        [[x_min, y_max], [x_max, y_max], [x_max, y_min], [x_min, y_min]]
      when "rd"
        [[x_max, y_max], [x_min, y_max], [x_min, y_min], [x_max, y_min]]
      when "ru"
        [[x_max, y_min], [x_min, y_min], [x_min, y_max], [x_max, y_max]]           
      when "lu"
        [[x_min,y_min], [x_max, y_min], [x_max, y_max], [x_min, y_max]]
      else
        raise "#{origin} not supported."
      end
    end

    def self.filepath_for(path, opts = {})
        extname = File.extname(path).sub(/\./,'')
        if opts[:ext]
          extname = opts[:ext].to_s
          extname = "geo" if extname == "vs"
        end
        dirname = File.dirname(path)
        dirname = File.join(dirname,opts[:insert_path]) if opts[:insert_path]
        File.join(dirname, File.basename(path, ".*") + ".#{extname}")
    end



    def initialize(opts = {})
      @verbose  = opts[:verbose] || false
      @name = opts[:name]
      @size = opts[:size]
      @locate = opts[:locate]
      @center = opts[:center]
      @pixs = opts[:pixs]
      @pixels_per_um = opts[:pixels_per_um]
      @magnification = opts[:magnification]
      unless @maginification
        @magnification = 120_000/@size[0] if @size && @size[0]
      end

      unless @pixels_per_um
        @pixels_per_um = @pixs[0]/@size[0] if @pixs && @size
      end
  #    @stage_origin = opts[:stage_origin] || "lu"

  #    @@opencvtool = OpenCvTool.new(:verbose => @verbose)
    end

    def self.image_dimension(path)
      pixs = Dimensions.dimensions(path)
    end
    
    def self.load(path, opts = {})
      pixs = Dimensions.dimensions(path)
      if File.exist?(filepath_for(path, :ext => :vs))
         this = from_file(filepath_for(path, :ext => :vs))
      elsif File.exist?(filepath_for(path, :ext => :txt))
         this = from_sem_info(filepath_for(path, :ext => :txt), opts[:stage2world])
      else
         this = self.new(:pixs => pixs)
      end
      this.image_path = path
      #this = self.new(:pixs => pixs)
      return this
    end

    def self.setup_dir(dir)
      Dir.mkdir(dir) unless File.directory?(dir)
    end

    def crop(opts = {})
        cropped_image = opts[:path]
        unless cropped_image
          dirname = File.dirname(image_path)
          basename = File.basename(image_path, ".*")
          extname = File.extname(image_path)
          cropped_image = File.join(dirname, basename + '_crop' + extname) 
        end
        crop_percent = opts[:crop_percent] || 0
        crop_width = (pixs[0] * (100 - crop_percent)/100.0).round
        crop_height = (pixs[1] * (100 - crop_percent)/100.0).round
        crop_start_x = ((pixs[0] - crop_width)/2).round
        crop_start_y = ((pixs[1] - crop_height)/2).round
        crop_end_x = crop_start_x + crop_width
        crop_end_y = crop_start_y + crop_height
        # must setup directory
  #      opencvtool = OpenCvTool.new
        opencvtool.crop_image(image_path, :geometry => "#{crop_width}x#{crop_height}+#{crop_start_x}+#{crop_start_y}", :output_file => cropped_image)
        crop_width_in_um = crop_width.to_f/pixs[0] * size[0]
        crop_height_in_um = crop_height.to_f/pixs[1] * size[1]
        cropped_image_info = ImageInfo.new(:name => name, :locate => locate, :center => [crop_width_in_um/2, crop_height_in_um/2], :size => [crop_width_in_um, crop_height_in_um], :pixs => [crop_width, crop_height])
        cropped_image_info.image_path = cropped_image

        tcorners_on_world = opencvtool.transform_points([[crop_start_x, crop_start_y],[crop_end_x, crop_start_y],[crop_end_x, crop_end_y],[crop_start_x, crop_end_y]], :matrix => affine(:pixs2world))      
        affine_image2world = opencvtool.H_from_points(cropped_image_info.corners_on_image, tcorners_on_world)
        cropped_image_info.set_affine(affine_image2world, :image2world)
        cropped_image_info.info_path = self.class.filepath_for(cropped_image, :ext => :vs)
        cropped_image_info.dump_info

        return cropped_image_info
    end

    def warp(opts = {})
        warp_image = opts[:path]
        unless warp_image
          dirname = File.dirname(image_path)
          basename = File.basename(image_path, ".*")
          extname = File.extname(image_path)
          warp_image = File.join(dirname, basename + '_warp' + extname) 
        end

        xs = corners_on_world.map{|x,y| x}.uniq
        x_range = xs.minmax
        ys = corners_on_world.map{|x,y| y}.uniq
        y_range = ys.minmax
        warp_locate = [ (x_range[1] + x_range[0])/2, (y_range[1] + y_range[0])/2 ]
        warp_size = [ x_range[1] - x_range[0], y_range[1] - y_range[0] ]
        warp_center = [ warp_size[0]/2, warp_size[1]/2 ]
        warp_pixs = warp_size.map{|v| (v * pixels_per_um).ceil }
        warp_image_info = ImageInfo.new(:name => name, :locate => warp_locate, :center => warp_center, :size => warp_size, :pixs => warp_pixs)
        corners_on_warp_image = [[0.0,0.0], [warp_size[0], 0.0], [warp_size[0], warp_size[1]],[0,warp_size[1]]]
        tcorners_on_world = [[x_range[0],y_range[1]],[x_range[1],y_range[1]],[x_range[1],y_range[0]],[x_range[0],y_range[0]]]
        affine_image2world = opencvtool.H_from_points(corners_on_warp_image, tcorners_on_world)
        warp_image_info.set_affine(affine_image2world, :image2world)
        corners_on_vs_image = opencvtool.transform_points(corners_on_world, :matrix => warp_image_info.affine(:world2pixs))
        opencvtool.warp_image(image_path, :corners => corners_on_vs_image, :geometry => warp_image_info.pixs, :output_file => warp_image)
        warp_image_info.image_path = warp_image
        warp_image_info.info_path = self.class.filepath_for(warp_image, :ext => :vs)
        warp_image_info.dump_info
        return warp_image_info
    end

    def set_affine(m, affine_type = :image2world)
      case affine_type
      # when :stage2world
      #   @affine_stage2world = m
      #   @affine_image2world = opencvtool.H_from_points(corners_on_image, corners_on_world)
      #   @affine_imagexy2world = opencvtool.H_from_points(corners_on_xy, corners_on_world)
      #   @affine_world2pixs = opencvtool.H_from_points(corners_on_world, corners_on_pixs)
      when :image2world
        @affine_image2world = m
        @affine_imagexy2world = opencvtool.H_from_points(corners_on_xy, corners_on_world)
        @affine_world2pixs = opencvtool.H_from_points(corners_on_world, corners_on_pixs)
        @affine_pixs2world = opencvtool.H_from_points(corners_on_pixs, corners_on_world)
        @affine_world2image = opencvtool.H_from_points(corners_on_world, corners_on_image)      
      when :imagexy2world
        @affine_imagexy2world = m

      when :world2pixs
        @affine_world2pixs = m
      else
        raise "unknown affine type [#{affine_type}]"
      end
    end

    def affine(affine_type)
      case affine_type
      # when :stage2world
      #   @affine_stage2world
      when :image2world
        @affine_image2world
      when :imagexy2world
        @affine_imagexy2world
      when :world2pixs
        @affine_world2pixs
      when :pixs2world
        @affine_pixs2world     
      else
        raise "unknown affine_type [#{affine_type}]"
      end
    end


    def self.from_image_path(image_path)
      raise "cannot read #{image_path}" unless File.exist?(image_path)
      this = self.new
      Dimensions.dimensions(image_path)

      cmd = "identify -format \"%w %h\" #{image_path}"
      r = `#{cmd}`
      if !r.empty?
        val = r.chomp.split(" ")
        this.width_in_pix = val[0].to_i
        this.height_in_pix = val[1].to_i
        this.pixs = val.map{|v| v.to_i }
      end
      dir = File.dirname(image_path)
      basename = File.basename(image_path, ".*")
      extname = File.extname(image_path)
      image_info_file = File.join(dir, basename + ".info")
      raise "cannot read #{image_path}" unless File.exist?(image_info_file)

      info_h = YAML::load_file(image_info_file)
      info_h.each do |key, val|
        this.send((key.to_s + "=").to_sym, val)
      end
      this
    end

    def self.textfile2array(path)
      a = []
      File.open(path).each do |line|
        a << line.chomp
      end
      a
    end

    def self.split_line(line, delimiter = nil)
      line.split(delimiter)
    end

    def self.replace_invalid_string(text)
      text.encode("UTF-16BE","UTF-8",invalid: :replace, undef: :replace, replace: '?').encode("UTF-8")
    end

    def self.parse_sem_info(text)
      h = Hash.new
      text = replace_invalid_string(text)
      text.split("\n").each do |line|
        if /CM_TITLE/ =~line
          vals = line.split
          h[:title] = vals[1]
          #h[:name] = vals[1]
        end
        
        if m = /CM_MAG (\d+)/.match(line)
          h[:magnification] = m[1].to_f
        end
        
        if m = /CM_FULL_SIZE (\d+) (\d+)/.match(line)
          h[:width_in_pix] = m[1].to_i
          h[:height_in_pix] = m[2].to_i
        end
        
        if /CM_STAGE_POS/ =~line
          vals = line.split
          stage_position = vals[1..-1].map{|v| v.to_f }
          h[:stage_x_in_um] = stage_position[0] * 1000
          h[:stage_y_in_um] = stage_position[1] * 1000          
        end
        
        if m = /SM_SCAN_ROTATION (\d+)/.match(line)
          h[:scan_rotation] = m[1].to_f          
        end
      end
      return h
    end

    def self.distance(p1, p2)
      Math.sqrt((p2[0] - p1[0])**2 + (p2[1] - p1[1])**2)
    end

    def self.from_sem_info(path, stage2world, opts = {})
      raise 'specify stage2world' unless stage2world
      h = Hash.new
      lines = textfile2array(path)
      h = parse_sem_info(lines.join("\n"))
      width_in_um = 12.0 * 10 * 1000 / h[:magnification]
      height_in_um = h[:height_in_pix] * width_in_um / h[:width_in_pix]
      pixels_per_um = h[:width_in_pix] / width_in_um
      center_on_stage = [h[:stage_x_in_um], h[:stage_y_in_um]]
      size = [width_in_um, height_in_um]
      center = [width_in_um/2.0, height_in_um/2.0]
      corners_on_stage = self.corners_on_stage(:center => center_on_stage, :size => size, :origin => 'ru')
      corners_on_world = opencvtool.transform_points(corners_on_stage, :matrix => stage2world)

      width_on_world = sprintf("%.3f", distance(corners_on_world[0],corners_on_world[1])).to_f
      height_on_world = sprintf("%.3f",distance(corners_on_world[1],corners_on_world[2])).to_f
      size = [width_on_world, height_on_world]
      corners_on_image = [[0.0,0.0], [width_on_world, 0.0], [width_on_world, height_on_world],[0,height_on_world]]
      affine_image2world = opencvtool.H_from_points(corners_on_image, corners_on_world)
      center = [width_on_world/2.0, height_on_world/2.0]
      locate = opencvtool.transform_points([center], :matrix => affine_image2world)[0]
      maginification = 12.0 * 10 * 1000 / width_on_world
      this = self.new(:name => h[:title], :locate => locate, :size => size, :center => center, :pixs => [h[:width_in_pix],h[:height_in_pix]])
      if opts[:image_path]
          this.image_path = opts[:image_path] 
          this.image_dimensions = Dimensions.dimensions(opts[:image_path])
      end
      this.set_affine(affine_image2world, :image2world)
      this.info_path = filepath_for(path, :ext => :vs)
      this.dump_info
      this
    end

    def magnification
      return 12.0 * 10 * 1000 / size[0] 
    end

    def imag
      maginification
    end

    def self.from_txt(path)
      h = Hash.new
      #begin
        File.open(path).each do |line|
          line.chomp!
          if /CM_TITLE/ =~line
            vals = line.split
            h[:title] = vals[1]
            #h[:name] = vals[1]
          end
          
          if m = /CM_MAG (\d+)/.match(line)
            h[:magnification] = m[1].to_f
          end
          
          if m = /CM_FULL_SIZE (\d+) (\d+)/.match(line)
            h[:width_in_pix] = m[1].to_i
            h[:height_in_pix] = m[2].to_i
          end
          
          if /CM_STAGE_POS/ =~line
            vals = line.split
            stage_position = vals[1..-1].map{|v| v.to_f }
            h[:stage_x_in_um] = stage_position[0] * 1000
            h[:stage_y_in_um] = stage_position[1] * 1000          
          end
          
          if m = /SM_SCAN_ROTATION (\d+)/.match(line)
            h[:scan_rotation] = m[1].to_f          
          end
          
        end

        width_in_um = 12.0 * 10 * 1000 / h[:magnification]
        height_in_um = h[:height_in_pix] * width_in_um / h[:width_in_pix]
        pixels_per_um = h[:width_in_pix] / width_in_um
        locate = [h[:stage_x_in_um], h[:stage_y_in_um]]
        size = [width_in_um, height_in_um]
        center = [width_in_um/2.0, height_in_um/2.0]
        this = self.new(:name => h[:title], :locate => locate, :size => size, :center => center, :magnification => h[:magnification], :pixs => [h[:width_in_pix],h[:height_in_pix]], :pixels_per_um => pixels_per_um, :stage_origin => "ru")
        return this
    end

    def pixels_per_um
      pixs[0] / size[0]
    end

    def dump_info
      dump(info_path)
    end

    def dump(path, opts = {})
      output = opts[:output] || STDOUT
      h = to_hash
      h["locate"] = locate
  #    h["affine_device2vs"] = affine(:stage2world)
      h["affine_image2vs"] = affine(:image2world)
      h["affine_xy2vs"] = affine(:imagexy2world)

      pairs = []
      vs = corners_on_world
      image = corners_on_image
      xy = corners_on_xy
  #    device = corners_on_stage
      vs.size.times do |idx|
        pair = Hash.new
        pair["image"] = image[idx]
        pair["vs"] = vs[idx]
  #      pair["device"] = device[idx]
        pair["xy"] = xy[idx]
        pairs << pair
      end
      h["pairs"] = pairs
      output.puts "#{path} writing..." if @verbose
      open(path, "w") do |f|
        f.write(YAML::dump(h))
        f.flush
      end
    end

    def self.from_file(info_file)
      h = YAML.load_file(info_file)
      opts = Hash.new
      h.each do |key,val|
        opts[key.to_sym] = val
      end
      obj = self.new(opts)
      obj.set_affine(opts[:affine_image2vs], :image2world)
      obj.info_path = info_file
      obj
    end

    def to_params_for_image_file
      to_params
    end

    def to_params_for_info_file
      params = to_params
      params.delete(:locate)    
      params.delete(:size)
      params.delete(:center)
      params.delete(:imag)
      return params
    end

    def to_params
      h = Hash.new
      h[:name] = name
      h[:locate] = locate
      h[:size] = size
      h[:center] = center
      h[:imag] = magnification
      return h
    end

    def to_hash
      h = Hash.new
      h["name"] = name
      h["locate"] = locate
      h["size"] = size
      h["pixs"] = pixs
      h["center"] = center
      # h["magnification"] = magnification
      # h["pixels_per_um"] = pixels_per_um
      # h["stage_origin"] = stage_origin
      return h
    end



    def corners_on_stage(opts = {})
      ranges = []
      2.times do |i|
        range = []
        range << locate[i] - center[i]
        range << locate[i] + (size[i] - center[i])
        ranges << range
      end

      x_min, x_max = ranges[0]
      y_min, y_max = ranges[1]
      origin = opts[:origin] || @stage_origin

      case origin
      when "ld"
        [[x_min, y_max], [x_max, y_max], [x_max, y_min], [x_min, y_min]]
      when "rd"
        [[x_max, y_max], [x_min, y_max], [x_min, y_min], [x_max, y_min]]
      when "ru"
        [[x_max, y_min], [x_min, y_min], [x_min, y_max], [x_max, y_max]]           
      when "lu"
        [[x_min,y_min], [x_max, y_min], [x_max, y_max], [x_min, y_max]]
      else
        raise "#{origin} not supported."
      end
    end
    
    def corners_on_image
      [[0.0,0.0], [size[0], 0.0], [size[0], size[1]], [0.0, size[1]]]
    end

    def corners_on_pixs
      [[0,0],[pixs[0],0],[pixs[0],pixs[1]],[0,pixs[1]]]
    end

    def corners_on_xy
      l = pixs[0]
      l = pixs[1] if pixs[1] > pixs[0]
      l = l.to_f
      if image_dimensions
        bottom_pix = image_dimensions[1] - pixs[1]
        yyy = image_dimensions[1]/l/2.0*100
        dy = bottom_pix/l/2.0*100
      else
        dy = 0
      end
      xx = pixs[0]/l/2.0*100
      yy = pixs[1]/l/2.0*100
      ty = yy + dy
      by = yy - dy
      [[-xx,ty],[xx,ty],[xx,-by],[-xx,-by]]
    end

    def locate_on_world
      l = locate
      if opencvtool && affine(:stage2world)
        return opencvtool.transform_points([locate], :matrix => affine(:stage2world))[0]
      else
        return l
      end
    end

    def corners_on_world
      # cs = corners_on_stage
      # if opencvtool && affine(:stage2world)
      #   return opencvtool.transform_points(cs, :matrix => affine(:stage2world))
      # else
      #   return cs
      # end
      if affine(:image2world)
        return opencvtool.transform_points(corners_on_image, :matrix => affine(:image2world))
      else
        return corners_on_image
      end
    end

  end
end