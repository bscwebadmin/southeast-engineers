# _plugins/static_image_cache.rb
# Skip copying static images unless they're new/changed.
# Keeps URLs the same. No transforms. Fast builds.
#
# Config (_config.yml):
# static_image_cache:
#   folders: ["uploads", "assets/img"]   # where your source images live
#   exts:    ["jpg","jpeg","png","gif","webp","svg"]
#   cache_file: ".jekyll-cache/static_image_hashes.json"
#   mirror_dir: ".jekyll-cache/static-images"   # a persistent mirror for cold builds
#   assume_persisted_site: false                # if true and file unchanged, don't write at all

require "digest"
require "json"
require "fileutils"

module Jekyll
  module StaticImageCache
    def self.cfg(site)
      defaults = {
        "folders" => ["uploads", "assets/img"],
        "exts"    => %w[jpg jpeg png gif webp svg],
        "cache_file" => ".jekyll-cache/static_image_hashes.json",
        "mirror_dir" => ".jekyll-cache/static-images",
        "assume_persisted_site" => false
      }
      defaults.merge(site.config.fetch("static_image_cache", {}))
    end

    def self.load_cache(path)
      return {} unless File.exist?(path)
      JSON.parse(File.read(path))
    rescue
      {}
    end

    def self.save_cache(path, data)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(data))
    rescue => e
      Jekyll.logger.warn "StaticImageCache:", "could not write cache (#{path}): #{e.message}"
    end

    def self.sha256(path)
      digest = Digest::SHA256.new
      File.open(path, "rb") do |f|
        buf = +""
        digest.update(buf) while f.read(1024 * 1024, buf)
      end
      digest.hexdigest
    end

    # A StaticFile that decides at write-time whether to copy, restore from mirror, or skip.
    class CachedImageFile < StaticFile
      def initialize(site, base, dir, name, options)
        super(site, base, dir, name, nil)
        @options = options
        @site_rel = File.join(dir, name) # relative to site.source
      end

      def write(dest)
        cfg          = StaticImageCache.cfg(@site)
        cache_path   = cfg["cache_file"]
        mirror_root  = File.join(@site.source, cfg["mirror_dir"])
        dest_path    = destination(dest)  # where Jekyll would write
        src_path     = path               # absolute source path
        assume_site  = !!cfg["assume_persisted_site"]

        FileUtils.mkdir_p(File.dirname(dest_path))

        cache = StaticImageCache.load_cache(File.join(@site.source, cache_path))
        current = StaticImageCache.sha256(src_path)
        prev    = cache[@site_rel]

        # If unchanged…
        if prev == current
          if assume_site
            # Assume previous _site still has the file; do nothing.
            return false
          end

          # Try to restore quickly from mirror if _site is cold.
          mirror_path = File.join(mirror_root, @site_rel)
          if File.exist?(mirror_path)
            FileUtils.mkdir_p(File.dirname(dest_path))
            FileUtils.cp(mirror_path, dest_path)
            return true
          end

          # Fallback: minimal copy from source (first time after cache was wiped).
          FileUtils.cp(src_path, dest_path)
          # Also refresh mirror for next time.
          FileUtils.mkdir_p(File.dirname(mirror_path))
          FileUtils.cp(dest_path, mirror_path)
          return true
        end

        # Changed or new: copy and update cache + mirror
        FileUtils.cp(src_path, dest_path)
        mirror_path = File.join(mirror_root, @site_rel)
        FileUtils.mkdir_p(File.dirname(mirror_path))
        FileUtils.cp(dest_path, mirror_path)

        cache[@site_rel] = current
        StaticImageCache.save_cache(File.join(@site.source, cache_path), cache)
        true
      rescue => e
        Jekyll.logger.warn "StaticImageCache:", "failed on #{@site_rel}: #{e.message}"
        # Let Jekyll try the default behavior if something went wrong
        super
      end
    end
  end

  # Replace matching image StaticFiles with CachedImageFile
  class StaticImageCacheInjector < Generator
    safe true
    priority :low

    def generate(site)
      cfg = StaticImageCache.cfg(site)
      folders = Array(cfg["folders"]).map(&:to_s)
      exts    = Array(cfg["exts"]).map { |e| e.to_s.downcase.delete(".") }

      site.static_files.map! do |sf|
        # Only intercept files under the chosen folders with matching extensions
        # and that originate from site.source (not gems).
        begin
          rel_from_source = sf.path.sub(site.source + File::SEPARATOR, "")
        rescue
          next sf
        end

        next sf unless folders.any? { |root| rel_from_source.start_with?(root + "/") }
        ext = File.extname(sf.path).downcase.delete(".")
        next sf unless exts.include?(ext)

        StaticImageCache::CachedImageFile.new(site, site.source, sf.dir, sf.name, cfg)
      end

      Jekyll.logger.info "StaticImageCache:", "watching #{folders.join(", ")} (#{exts.join(", ")})"
    end
  end
end
