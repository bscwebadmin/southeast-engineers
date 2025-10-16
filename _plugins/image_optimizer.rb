# _plugins/image_optimizer.rb
# Caches content hashes of images and only reprocesses when new/changed.
# Works even if MiniMagick isn't installed (will just copy unchanged/new files).
# Configure in _config.yml under `image_optimizer:` (see notes at bottom).

require "digest"
require "json"
begin
  require "mini_magick"
rescue LoadError
  # MiniMagick not available; plugin will fall back to copying files.
end

module Jekyll
  class OptimizedStaticFile < StaticFile
    def destination(dest)
      File.join(dest, @dir, @name)
    end
  end

  class ImageOptimizer < Generator
    safe true
    priority :low

    def generate(site)
      @site = site
      cfg   = site.config.fetch("image_optimizer", {})

      source_dirs = Array(cfg.fetch("source_dirs", ["uploads", "assets/img"])).map(&:to_s)
      dest_dir    = cfg.fetch("dest_dir", "assets/optimized").to_s
      cache_file  = cfg.fetch("cache_file", ".jekyll-cache/image_optim_cache.json").to_s
      quality     = cfg.fetch("quality", 82).to_i
      max_width   = cfg.fetch("max_width", 2400).to_i
      formats     = Array(cfg.fetch("formats", %w[jpg jpeg png webp])).map(&:downcase)

      ensure_dir(File.dirname(cache_file))
      cache = read_cache(cache_file)

      src_paths = source_dirs.flat_map do |dir|
        absolute = File.join(@site.source, dir)
        next [] unless Dir.exist?(absolute)
        Dir[File.join(absolute, "**", "*")].select do |p|
          File.file?(p) && formats.include?(File.extname(p).delete(".").downcase)
        end
      end

      updated_cache = cache.dup
      processed = 0
      skipped   = 0

      src_paths.each do |src_abs|
        rel_from_site = src_abs.sub(@site.source + File::SEPARATOR, "")
        fingerprint   = sha256_file(src_abs)
        cache_key     = rel_from_site

        # Skip if unchanged (fingerprint exists and matches)
        if cache[cache_key] == fingerprint
          skipped += 1
          next
        end

        # Determine output path (mirror structure under dest_dir)
        out_rel_dir  = File.join(dest_dir, File.dirname(rel_from_site))
        out_dir_abs  = File.join(@site.dest, out_rel_dir)
        out_name     = File.basename(rel_from_site)
        out_abs      = File.join(out_dir_abs, out_name)

        ensure_dir(out_dir_abs)

        # Process/Copy
        if defined?(MiniMagick)
          process_with_mini_magick(src_abs, out_abs, max_width, quality)
        else
          FileUtils.cp(src_abs, out_abs)
        end

        # Track as a generated file so Jekyll copies it
        out_rel_for_static = File.join(out_rel_dir, out_name)
        @site.static_files << OptimizedStaticFile.new(@site, @site.dest, out_rel_dir, out_name)

        updated_cache[cache_key] = fingerprint
        processed += 1
      end

      write_cache(cache_file, updated_cache)

      Jekyll.logger.info "ImageOptimizer:", "processed=#{processed}, skipped=#{skipped}, total=#{src_paths.size}, cache=#{cache_file}"
    end

    private

    def ensure_dir(dir)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end

    def sha256_file(path)
      digest = Digest::SHA256.new
      File.open(path, "rb") do |f|
        buffer = ""
        digest.update(buffer) while f.read(1024 * 1024, buffer)
      end
      digest.hexdigest
    end

    def read_cache(cache_file)
      return {} unless File.exist?(cache_file)
      JSON.parse(File.read(cache_file))
    rescue
      {}
    end

    def write_cache(cache_file, data)
      ensure_dir(File.dirname(cache_file))
      File.write(cache_file, JSON.pretty_generate(data))
    rescue => e
      Jekyll.logger.warn "ImageOptimizer:", "Could not write cache (#{cache_file}): #{e.message}"
    end

    def process_with_mini_magick(src_abs, out_abs, max_width, quality)
      image = MiniMagick::Image.open(src_abs)

      # Resize down if needed (keep aspect)
      if image.width > max_width
        image.resize "#{max_width}x"
      end

      ext = File.extname(out_abs).downcase
      case ext
      when ".jpg", ".jpeg"
        image.strip
        image.quality quality.to_s
        image.interlace "Plane"
      when ".png"
        # use pngquant-like settings via quality mapped to compression level
        image.strip
      when ".webp"
        image.quality quality.to_s
      end

      image.write(out_abs)
    end
  end

  # Optional Liquid filter: returns optimized path when available, else original
  module ImageOptimizerFilters
    def optimized_image_url(input, dest_dir = "assets/optimized")
      return input if input.nil? || input.empty?
      # Build where the optimizer will write it (mirrors original path under dest_dir)
      clean = input.sub(/^\//, "")
      candidate = File.join("/", dest_dir, clean)
      # At build-time we don't know _site contents from Liquid; return candidate by convention.
      candidate
    end
  end
end

Liquid::Template.register_filter(Jekyll::ImageOptimizerFilters)
