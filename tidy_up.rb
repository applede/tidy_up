#!/usr/bin/env ruby
# $stdout.reopen("/Users/apple/Library/Logs/move_torrent.log", "w")
# $stderr = $stdout

NORMAL_SRC = "/Users/apple/Downloads/torrents/complete"
CP_SRC = "/Users/apple/Downloads/torrents/CouchPotato"
SICKRAGE_SRC = "/Users/apple/Downloads/torrents/SickRage"
TVSHOW_DST = "/Volumes/Raid3/thetvdb"

def remove_torrent(id)
  unless $test
    `transmission-remote --torrent #{id} --remove`
  end
  puts "  removed"
end

def move_file(src, dst)
  if File.exist?(src)
    unless $test
      `mv -n "#{src}" "#{dst}"`
    end
  end
end

def remove_dir(dir)
  unless $test
    `rm -rf "#{dir}"`
  end
end

def remove_file(path)
  unless $test
    `rm "#{path}"`
  end
end

def red(str)
  "\e[31m#{str}\e[0m"
end

def green(str)
  "\e[32m#{str}\e[0m"
end

def yellow(str)
  "\e[33m#{str}\e[0m"
end

def blue(str)
  "\e[34m#{str}\e[0m"
end

def purple(str)
  "\e[35m#{str}\e[0m"
end

def cyan(str)
  "\e[36m#{str}\e[0m"
end

def grey(str)
  "\e[37m#{str}\e[0m"
end

def inverse(str)
  "\e[30;47m#{str}\e[0m"
end

def pad(str, width)
  str = str.to_s
  if str.length < width
    str + " " * (width - str.length)
  else
    str
  end
end

def pretty_number(num)
  num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

$names = []

def register_name(name)
  if not $names.include?(name)
    $names += [name]
    $names.sort!.reverse!
  end
end

TO_REMOVE = [
  " Xxx 1080p Xxxmegathor",
  " Xxx 1080p Cporn",
  " Xxx Mp4 Cporn",
  " Xxx 1080p Sexyxpixels",
  " Sexors",
  " Xxx 1080p Bty",
  " Xxx 1080p Mp4-ktr",
  " 1080p",
  " (2013) [1080p]",
  " [1080p]",
  " Fullhd",
  " (720p)",
  " Xxx 720p Mov-ktr",
  " Xxx B00bastic",
  " Xxx 720p Pornalized",
  " 1080",
  " Hd1080"
]

class Entry
  attr :label, :names, :remain, :ext, :src_folder, :dst_folder, :orig_name

  def initialize(src_folder, dst_folder, filename)
    @src_folder = src_folder
    @dst_folder = dst_folder
    @orig_name = filename
    @remain = @orig_name
    @names = []
  end

  def to_s
    if @label && @names && @names.length > 0
      "#{@label} - #{green(@names.join(", "))} - #{cyan(@remain)}.#{@ext}"
    elsif @label
      red("#{@label} - #{@remain}.#{@ext}")
    else
      red("#{@remain}.#{@ext}")
    end
  end

  def keep?()
    ["mp4", "mkv", "MKV", "avi", "smi"].include?(@ext) &&
    !(@remain =~ /^RARBG.com/)
  end

  def new_filename
    self.to_s.gsub(/\e\[\d+m/, "")
  end

  def register_names()
    @names.each do |name|
      register_name(name)
    end
  end

  def name_changed?()
    new_filename() != @orig_name
  end

  def rename()
    src_path = "#{@src_folder}/#{@orig_name}"
    dst_path = "#{@dst_folder}/#{new_filename()}"
    if File.exist?(dst_path)
      puts "  #{red('file exist')} #{pad(self, 64)} <= #{@orig_name}"
      src_size = File.size(src_path)
      dst_size = File.size(dst_path)
      if src_size == dst_size
        puts "    same size => #{green('delete src')}"
        remove_file(src_path)
      elsif src_size > dst_size
        puts "    src=#{pretty_number(src_size)} > dst=#{pretty_number(dst_size)} => #{yellow('overwrite')}"
        unless $test
          `mv -f "#{src_path}" "#{dst_path}"`
        end
      else
        puts "    src=#{pretty_number(src_size)} < dst=#{pretty_number(dst_size)} => #{yellow('delete src')}"
        remove_file(src_path)
      end
    else
      puts "  #{pad(self, 75)} <= #{@orig_name}"
      if not $test
        `mv "#{src_path}" "#{dst_path}"`
      end
    end
  end

  def copy()
    src_path = "#{@src_folder}/#{@orig_name}"
    dst_path = "#{@dst_folder}/#{new_filename()}"
    if File.exist?(dst_path)
      puts yellow("  file exist #{dst_path}")
      src_size = File.size(src_path)
      dst_size = File.size(dst_path)
      if src_size == dst_size
        puts green("  same size")
        return true
      elsif src_size > dst_size
        puts "  src=#{pretty_number(src_size)} > dst=#{pretty_number(dst_size)} => #{yellow('overwrite')}"
        unless $test
          `cp -n "#{src_path}" "#{dst_path}"`
        end
        return true
      else
        puts "  src=#{pretty_number(src_size)} < dst=#{pretty_number(dst_size)} => #{yellow('skip')}"
      end
    else
      puts "  #{green('copy')} #{@orig_name} to #{@dst_folder}/#{self}"
      if not $test
        `cp "#{src_path}" "#{dst_path}"`
      end
    end
  end

  def parse_ext()
    if @orig_name =~ /^(.+)\.(\w+)$/
      @remain = $1
      @ext = $2
    end
  end

  # return true if label is parsed
  def parse_label()
    if @remain =~ /^(SexArt|JoyMii|X-Art|WowGirls)(.+)$/
      @label = $1
      @remain = $2
      true
    elsif @remain =~ /^wowg\.\d\d\.\d\d\.\d\d\.(.+)$/
      @label = "WowGirls"
      @remain = $1
      true
    elsif @remain =~ /^sart\.\d\d\.\d\d\.\d\d\.(.+)$/ ||
	  @remain =~ /^(.+)-SexArt-1080p$/
      @label = "SexArt"
      @remain = $1
    elsif @remain =~ /^xart\.\d\d\.\d\d\.\d\d\.(.+)$/ ||
          @remain =~ /^x-art_(.+)$/ ||
          @remain =~ /^X\.Art\.\d\d\.\d\d\.\d\d\.(.+)$/ ||
          @remain =~ /^x\.art\.(.+)$/
      @label = "X-Art"
      @remain = $1
    elsif @remain =~ /^Joymii\.(.+)$/ ||
          @remain =~ /^joymii\.\d\d\.\d\d\.\d\d\.(.+)$/
      @label = "JoyMii"
      @remain = $1
    else
      false
    end
  end

  # return true if it is well formed name
  def parse_well_formed()
    # not to alter @remain in case of match failure
    str = @remain.gsub(/ aka [[:alpha:]]+( [[:alpha:]]+)?/, '')       # remove aka Abc
    str = str.gsub(/ ([[:alpha:]])\. /, ' \1 ')   # convert A. -> A
    if str =~ /^ - (.+) - (\w+( \w+){0,2}) \[1080p\]$/
      @remain = $1
      @names = [$2]
      register_names()
      true
    elsif str =~ /^ - (.+) - ([[:alpha:]]+( [[:alpha:]]+){0,2}(, \w+([- ]\w+){0,2})*) \[1080p\]$/
      @remain = $1
      @names = $2.split(', ').map { |x| x.gsub('-', ' ') }
      register_names()
      true
    elsif str =~ /^ - (.+) - ([[:alpha:]]+( [[:alpha:]]+){0,2}( and \w+([- ]\w+){0,2})*) \[1080p\]$/
      @remain = $1
      @names = $2.split(' and ')
      register_names()
      true
    elsif str =~ /^ - ([[:alpha:]]+) - ([[:alpha:]]+ [[:alpha:]]) - (.+)_1080p$/
      @remain = $3
      @names = [$1, $2]
      register_names()
      true
    elsif str =~ /^ - (\w+( \w+)?) \((.+?)\).*$/ ||
          str =~ /^ - (\w+( \w+)?) \{(.+?)\}.*$/
      @names = [$1]
      @remain = $3
      register_names()
      true
    elsif str =~ /^ - (\w+, \w+( \w\.)?) \((.+?)\).*$/
      @remain = $3    # do it before gsub
      @names = $1.split(', ').map { |x| x.gsub('.', '')}
      register_names()
      true
    elsif str =~ /^ - (\w+( \w+)*(, \w+( \w+)*)*) - (.+)$/
      @names = $1.split(", ")
      @remain = $5
      register_names()
      true
    elsif str =~ /^ - (Introducing (\w+)) .*$/ ||
          str =~ /^ - ((\w+)'s Hidden Cam) .*$/
      @names = [$2]
      @remain = $1
      register_names()
      true
    else
      false
    end
  end

  def convert_dot_space()
    @remain = @remain.split(".").map { |x| x.capitalize }.join(" ")
    @remain = @remain.split("_").map { |x| x.capitalize }.join(" ")
    @remain = @remain.split("-").map { |x| x.capitalize }.join(" ")
    @remain = @remain.split(" ").map { |x| x.capitalize }.join(" ")
  end

  # return true if it is "Name A" (A is initial)
  def parse_name_initial()
    if @remain =~ /^ - (\w+ \w) (.+)$/
      @names += [$1]
      @remain = $2
      register_names()
      true
    else
      false
    end
  end

  def skip?(pos, str)
    if match?(@remain, pos, str)
      pos += str.length
    end
    pos
  end

  def parse_names()
    pos = 0
    pos = skip?(pos, "- ")
    names = []
    while name_pos = match_any?(@remain, pos, $names)
      (name, pos) = name_pos
      names += [name]
      if match?(@remain, pos, ", ")
        pos += 2
      end
    end
    if names.length > 0
      @names = names
      @remain = @remain[pos .. -1]
    end
  end

  def remove_garbage()
    if @remain =~ /^(.+) \d\d \d\d \d\d$/ ||
       @remain =~ /^(.+) \(\d\d\d\d\) 1080p$/ ||
       @remain =~ /^(.+) - HD 1080p - .+$/ ||
       @remain =~ /^(.+) \d\d \d\d \d\d H264 Ssxxx$/
      @remain = $1
    end
    TO_REMOVE.each do |str|
      if @remain.gsub!(str, "")
        break
      end
    end
  end

  def parse_episode()
    if @remain.gsub!(/ Ep(\d\d) /, ' S01E\1 ')
      true
    elsif @remain.gsub!(/_Ep(\d\d)_/, ' S01E\1 ')
      true
    elsif @remain.gsub!(/ (\d) - (\d\d) /, ' S0\1E\2 ')
      true
    else
      false
    end
  end

  def parse()
    parse_ext()
    if parse_label()
      if not parse_well_formed()
        if not parse_name_initial()
          convert_dot_space()
          parse_names()
        end
      end
      remove_garbage()
    elsif parse_episode()

    end

    return @label && @names && @names.length > 0 && @ext
  end
end

def match?(str, pos, pat)
  str.index(pat, pos) == pos
end

def match_any?(title, pos, names)
  if match?(title, pos, "And ")
    pos += 4
  end
  names.each do |name|
    if match?(title, pos, "#{name} ")
      return [name, pos + name.length + 1]
    end
  end
  return nil
end

# returns array of entries in the folders
def get_entries(*folders)
  entries = []
  folders.each do |folder|
    Dir.foreach(folder) do |file|
      if [".", "..", ".DS_Store"].include?(file)
        next
      end
      entries += [Entry.new(folder, folder, file)]
    end
  end
  return entries
end

# returns tuple of (number of processed entries, array of unrecognized names)
def process_entries(entries)
  unknown = []
  count = 0
  entries.each do |entry|
    if entry.parse()
      if entry.name_changed?()
        entry.rename()
        count += 1
      end
    else
      unknown += [entry]
    end
  end
  return [count, unknown]
end

def unrar_any(src_folder)
  Dir.foreach(src_folder) do |file|
    if file =~ /\.rar$/
      puts "  #{green('unrar')} #{file}"
      if not $test
        `unrar e -o+ "#{src_folder}/#{file}" "#{src_folder}/"`
      end
    end
  end
end

def copy_file(src_folder, dst_folder, file)
  entry = Entry.new(src_folder, dst_folder, file)
  entry.parse()
  if entry.keep?()
    entry.copy()
  else
    puts "  skip #{file}"
  end
end

# return false means the source doesn't exist so the torrent isn't removed
def process_general(src_folder, dst, name, id)
  `mkdir -p "#{dst}"`
  src = "#{src_folder}/#{name}"
  if File.exist?(src)
    if File.directory?(src)
      unrar_any(src)
      Dir.foreach(src) do |file|
        next if [".", ".."].include?(file)
        copy_file(src, dst, file)
      end
      remove_dir(src)
    else # single file
      copy_file(src_folder, dst, name)
      remove_file(src)
    end
    remove_torrent(id)
    return true
  else # maybe in different folder?
    puts "  src not exists"
    return false
  end
end

def process_porn(to_folder, name, id)
  process_general(NORMAL_SRC, "/Users/johndoe/Raid2/porn/#{to_folder}", name, id)
end

def process_tvshow(tvshow, season, name, id)
  if !process_general(SICKRAGE_SRC, "#{TVSHOW_DST}/#{tvshow}/Season #{season}", name, id)
    if !process_general(NORMAL_SRC, "#{TVSHOW_DST}/#{tvshow}/Season #{season}", name, id)
      remove_torrent(id)
    end
  end
end

def process_tvshow_folder(tvshow, name, id)
  src_folder = "#{NORMAL_SRC}/#{name}"
  if not File.exist?(src_folder)
    src_folder = "#{SICKRAGE_SRC}/#{name}"
  end

  dst_folder = "#{TVSHOW_DST}/#{tvshow}"
  Dir.foreach(src_folder) do |file|
    next if [".", ".."].include?(file)
    copy_file(src_folder, dst_folder, file)
  end
  remove_dir(src_folder)
  remove_torrent(id)
end

def process_movie(name, id)
  if name =~ /(.+)\.(\d\d\d\d)\.(.+)/ ||
     name =~ /(.+)\((\d\d\d\d)\)/
    title = $1
    year = $2.to_i
    if year >= 1930 && year <= 2050
      # title = title.gsub('.', ' ')
      title.gsub!(/(?<!Mr)\./, ' ')
      dst_folder = "/Users/johndoe/Movie2/#{title} (#{year})"
      unless File.exist?(dst_folder)
        `mkdir "#{dst_folder}"`
      end
      process_general(CP_SRC, dst_folder, name, id)
    else
      puts "  invalid year"
    end
  else
    puts red("  unknown name")
  end
end

def process_existing_files
  unknown_entries = get_entries("/Users/johndoe/Raid2/porn/SexArt",
                                "/Users/johndoe/Raid2/porn/JoyMii",
                                "/Users/johndoe/Raid2/porn/X-Art",
                                "/Users/johndoe/Raid2/porn/WowGirls")

  total = 0
  begin
    (processed, unknown_entries) = process_entries(unknown_entries)
    total += processed
  end until processed == 0
  if unknown_entries.length == 0
    if total == 0
      puts green("ok")
    end
  else
    puts red("unrecognized files")
    unknown_entries.each do |entry|
      puts "#{entry.orig_name} => #{entry.remain}"
    end
  end
end

$test = false
$verbose = false
ARGV.each do |arg|
  if arg == "-t" # test
    $test = true
  elsif arg == "-v" # verbose
    $verbose = true
  else
    $names += [arg]
  end
end

process_existing_files()

list = `transmission-remote --list`
list.split("\n").each do |line|
  id = line[0..3]
  status = line[57..67]
  name = line[70..-1]
  if status == "Finished   " ||
     status == "Stopped    "
    puts inverse(line)
    if name =~ /CSI.+S(\d\d)E\d\d\D/
      process_tvshow("CSI Crime Scene Investigation", $1, name, id)
    elsif name =~ /The.Big.Bang.Theory.S(\d\d)E\d\d\D/
      # don't touch for now
      process_tvshow("The Big Bang Theory", $1, name, id)
    elsif name =~ /The\.Flash\..+?S(\d\d)E\d\d\./
      process_tvshow("The Flash (2014)", $1, name, id)
    elsif name =~ /K-ON!/
      process_tvshow_folder("K-On!", name, id)
    elsif name =~ /Infinite Stratos/
      process_tvshow_folder("Infinite Stratos", name, id)
    elsif name =~ /Carl Sagan's Cosmos/
      process_tvshow_folder("Cosmos", name, id)
    elsif name =~ /Homeland\.S(\d\d)E\d\d\..+/
      process_tvshow("Homeland", $1, name, id)
    elsif name =~ /^(SexArt|WowGirls|X-Art|JoyMii)/i
      process_porn($1, name, id)
    elsif name =~ /^(sart\.)/i ||
	  name =~ /-SexArt-/
      process_porn('SexArt', name, id)
    elsif name =~ /^(X\.Art)/i
      process_porn('X-Art', name, id)
    else
      process_movie(name, id)
    end
  else
  end
end
