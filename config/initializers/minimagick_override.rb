MiniMagick::Image.class_eval do
  def format(format, page = 0, read_opts={})
    if @tempfile
      new_tempfile = MiniMagick::Utilities.tempfile(".#{format}")
      new_path = new_tempfile.path
    else
      new_path = Pathname(path).sub_ext(".#{format}").to_s
    end

    input_path = path.dup
    input_path << "-#{page}" if page && !layer?

    MiniMagick::Tool::Convert.new do |convert|
      read_opts.each do |opt, val|
        convert.send(opt.to_s, val)
      end
      convert << input_path
      yield convert if block_given?
      convert << new_path
    end

    if @tempfile
      destroy!
      @tempfile = new_tempfile
    else
      File.delete(path) unless path == new_path || layer?
    end

    path.replace new_path
    @info.clear

    self
  end
end
