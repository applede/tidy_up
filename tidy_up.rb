#!/usr/bin/env ruby
# $stdout.reopen("/Users/apple/Library/Logs/move_torrent.log", "w")
# $stderr = $stdout

NORMAL_SRC = "/Users/apple/Downloads/torrents/complete"
CP_SRC = "/Users/apple/Downloads/torrents/CouchPotato"
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

# fill names to help recognize names
$names = ["Alexa Tomas", "Tracy Lindsay", "Aria Salazar", "Candice Luka", "Cayenne Klein", "Eva Alegra",
          "Ferrera Gomez", "Nici Dee", "Paula Shy", "Tania G", "Naomi Nevena", "Bailey Ryder", "Sandy Ambrosia",
          "Jenny Simons", "Samantha Joons", "Jessie Jazz", "Ashley Woods", "Isabella Amor", "The Game",
          "Kamikaze Love", "Darla", "Kattie Gold", "Candice Luca", "Eveline"]

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
  " Xxx 720p Pornalized"
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
    else
      "#{@remain}.#{@ext}"
    end
  end

  def keep?()
    ["mp4", "mkv", "avi", "smi"].include?(@ext)
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
    new_path = "#{@dst_folder}/#{new_filename()}"
    if File.exist?(new_path)
      puts red("  file exist #{new_path}")
    else
      if not $test
        `mv "#{@src_folder}/#{@orig_name}" "#{@dst_folder}/#{new_filename()}"`
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
      elsif src_size > dst_size
        puts "  src=#{src_size} > dst=#{dst_size}"
        puts yellow("  overwrite")
        unless $test
          `cp -n "#{src_path}" "#{dst_path}"`
        end
      else
        puts "  src=#{src_size} < dst=#{dst_size}"
        puts green("  skip")
      end
    else
      puts "  #{green('copy')} #{self} to #{@dst_folder}"
      if not $test
        `cp "#{src_path}" "#{dst_path}"`
      end
    end
  end

  # return true if well formed
  # def well_formed?
  #   if @orig_name =~ /^(.+)\.(\w+)$/
  #     @remain = $1
  #     @ext = $2
  #   end
  #   parts = @title.split(" - ")
  #   if parts.length != 3
  #     return false
  #   end

  #   if not ["SexArt", "JoyMii", "X-Art", "WowGrils"].include?(parts[0])
  #     return false
  #   end
  #   @label = parts[0]

  #   names = parts[1].split(", ")
  #   names.each do |name|
  #     if name =~ %r{[[:alpha:]]+( [[:alpha:]]+)?}
  #     else
  #       return false
  #     end
  #   end
  #   @names = names
  #   if parts[2] =~ /^(.+)\.(\w+)$/
  #     self.names = names
  #     return Entry.new(parts[0], names, $1, $2)
  #   else
  #     return nil
  #   end
  # end

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
    elsif @remain =~ /^(wowg\.\d\d\.\d\d\.\d\d\.)(.+)$/
      @label = "WowGirls"
      @remain = $2
      true
    else
      false
    end
  end

  # return true if it is well formed name
  def parse_well_formed()
    if @remain =~ /^ - (.+) - (\w+) \[1080p\]$/
      @names = [$2]
      @remain = $1
      register_names()
      return true
    end
    if @remain =~ /^ - (\w+( \w+)*(, \w+( \w+)*)*) - (.+)$/
      @names = $1.split(", ")
      @remain = $5
      register_names()
      true
    else
      false
    end
  end

  def convert_dot_space()
    @remain = @remain.split(".").map { |x| x.capitalize }.join(" ")
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
    pos = skip?(pos, " - ")
    pos = skip?(pos, " ")
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
    if @remain =~ /^(.+) \d\d \d\d \d\d$/
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
          remove_garbage()
        end
      end
    elsif parse_episode()
        
    end

    return @label && @names && @names.length > 0 && @ext

    # t = @remain.split(".").map { |x| x.capitalize }.join(" ")
    # t = t.split(" ").map { |x| x.capitalize }.join(" ")
    # pos = 0
    # ns = []
    # while name_pos = start_with_names?(t, pos, $names) 
    #   (name, pos) = name_pos
    #   ns += [name]
    # end
    # while start_with?(t, pos, "- ")
    #   pos += 2
    # end
    # TO_REMOVE.each do |str|
    #   if t.gsub!(str, "")
    #     break
    #   end
    # end
    # if ns.length > 0 || t[pos..-1] != title
    #   self.names += ns
    #   self.title = t[pos..-1]
    #   return true
    # else
    #   return false
    # end
  end
end

# def register_words_list(words)
#   if words.length == 4
#     register_name(words[0] + " " + words[1])
#     register_name(words[2] + " " + words[3])
#   else
#     register_name(words.join(" "))
#   end
# end

# def find_name(file)
#   entry = well_formed?(file)
#   if entry
#     entry.names.each do |name| register_name(name) end
#     return
#   end
#   if file =~ /^SexArt - (.+) - (.+) \[1080p\]\.[^.]+$/
#     register_name($2)
#   elsif file =~ /^SexArt - (.+?) - .+\.[^.]+$/
#     $1.split(", ").each { |n| register_name(n) }
#   elsif file =~ /^sart\.\d\d\.\d\d\.\d\d\.(.+?)\.and\..+$/
#     register_words_list($1.split(".").map { |x| x.capitalize })
#   elsif file =~ /^\[SexArt\] ([^-]+) -.+$/
#     $1.split(", ").each { |n| register_name(n) }
#   elsif file =~ /^SexArt\.[\d.]*(.+?)\.And\..+$/
#     register_words_list($1.split("."))
#   elsif file =~ /^SexArt\.com - (.+?) - .+$/
#     register_name($1)
#   elsif file =~ /^TayTO-SexArt\.\d\d\.\d\d\.\d\d\.(.+?)\.And\..+$/
#     register_name($1.gsub(".", " "))
#   elsif file =~ /^SexArt\.([^.]+)\.([A-Z])\..+$/
#     register_name("#{$1} #{$2}")
#   elsif file =~ /^joymii\.\d\d\.\d\d\.\d\d\.([^.]+)\.([^.])\.and\.([^.]+)\.([^.])\..+$/ ||
#         file =~ /^Joymii - (\w+) (\w) and (\w+) (\w) - .+$/
#     register_name("#{$1.capitalize} #{$2.capitalize}")
#     register_name("#{$3.capitalize} #{$4.capitalize}")
#   elsif file =~ /^joymii\.\d\d\.\d\d\.\d\d\.([^.]+)\.([^.])\..+$/ ||
#         file =~ /^Joymii ([^ ]+) ([^ ]) .+$/
#     register_name("#{$1.capitalize} #{$2.capitalize}")
#   elsif file =~ /^joymii\.\d\d\.\d\d\.\d\d\.([^.]+)\.and\.([^.]+)\.(\w)\..+$/
#     register_name("#{$1.capitalize}")
#     register_name("#{$2.capitalize} #{$3.capitalize}")
#   elsif file =~ /^joymii\.\d\d\.\d\d\.\d\d\.([^.]+)\.and\.([^.]+)\..+$/
#     register_name("#{$1.capitalize}")
#     register_name("#{$2.capitalize}")
#   elsif file =~ /^joymii\.\d\d\.\d\d\.\d\d\.([^.]+)\..+$/
#     register_name($1.capitalize)
#   elsif file =~ /^JoyMii - (.+?) - .+$/
#     $1.split(", ").each { |n| register_name(n) }
#   elsif file =~ /^JoyMii - \d\d \d\d \d\d (\w+ \w) And (\w+ \w) .+$/
#     register_name($1)
#     register_name($2)
#   end
# end

# def find_names(folder)
#   Dir.foreach(folder) do |file|
#     find_name(file)
#   end
# end

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

# def rename_title(name)
#   title = name.split(".").map { |x| x.capitalize }.join(" ")
#   title = title.split(" ").map { |x| x.capitalize }.join(" ")
#   pos = 0
#   names = []
#   while name_pos = start_with_names?(title, pos, $names) 
#     (name, pos) = name_pos
#     names += [name]
#   end
#   while start_with?(title, pos, "- ")
#     pos += 2
#   end
#   TO_REMOVE.each do |str|
#     if title.gsub!(str, "")
#       break
#     end
#   end
#   if names.length > 0
#     return "#{names.join(", ")} - #{title[pos .. -1]}"
#   else
#     return "#{title}"
#   end
# end

# return nil means file name is in correct form
# def rename(file)
#   if file =~ /^SexArt\.com - (.+?) - (.+) \[.+\].([^.]+)$/
#     title = rename_title("#{$1} #{$2}")
#     return "SexArt - #{title}.#{$3}"
#   elsif file =~ /^sart\.\d\d\.\d\d\.\d\d\.(.+)\.([^.]+)$/ ||
#         file =~ /^SexArt\.\d\d\.\d\d\.\d\d\.(.+)\.([^.]+)$/ ||
#         file =~ /^SexArt\.(.+)\.([^.]+)$/ ||
#         file =~ /^TayTO-SexArt\.\d\d\.\d\d\.\d\d\.(.+)\.([^.]+)$/ ||
#         file =~ /^SexArt (.+) 1080p\.([^.]+)$/
#     title = rename_title($1)
#     return "SexArt - #{title}.#{$2}"
#   elsif file =~ /^SexArt - (.+) - (.+) \[1080p\]\.([^.]+)$/
#     title = rename_title("#{$2} #{$1}")
#     return "SexArt - #{title}.#{$3}"
#   elsif file =~ /^\[SexArt\] (.+) - (.+) \(1080p\).*\.([^.]+)$/
#     title = rename_title("#{$1} #{$2}")
#     return "SexArt - #{title}.#{$3}"
#   elsif file =~ /^sexart\.\d\d\.\d\d\.\d\d\.([^.]+)\.([a-z])\.(.+)\.([^.]+)$/
#     title = rename_title("#{$1} #{$2} #{$3}")
#     return "SexArt - #{title}.#{$4}"
#   elsif file =~ /^Joymii - (\w+ \w and \w+ \w) - (.+)\.([^.]+)$/
#     title = rename_title("#{$1} #{$2}")
#     return "JoyMii - #{title}.#{$3}"
#   elsif file =~ /^JoyMii - ([^-]+)- (- )+(.+)\.([^.]+)$/
#     title = rename_title("#{$1} #{$3}")
#     return "JoyMii - #{title}.#{$4}"
#   elsif file =~ /^joymii\.\d\d\.\d\d\.\d\d\.(.+)\.([^.]+)$/ ||
#         file =~ /^Joymii\.(.+)\.([^.]+)$/ ||
#         file =~ /^JoyMii - \d\d \d\d \d\d (.+)\.([^.]+)$/ ||
#         file =~ /^JoyMii - ([^-]+)\.([^.]+)$/ ||
#         file =~ /^Joymii - (.+)\.([^.]+)$/ ||
#         file =~ /^Joymii (.+)\.(\w+)$/ ||
#         file =~ /^JoyMii - (.+) Xxx \w+\.(\w+)$/ ||
#         file =~ /^JoyMii (.+) Xxx 720p \w+\.(\w+)$/
#     title = rename_title($1)
#     return "JoyMii - #{title}.#{$2}"
#   elsif file =~ /^SexArt - .+? - .+$/ ||
#         file =~ /^JoyMii - .+? - .+$/
#     # correct one
#     return nil
#   else
#     puts red(file)
#   end
#   return file
# end

# def rename_files_(folder)
#   Dir.foreach(folder) do |file|
#     if file == "." || file == ".." || file == ".DS_Store"
#       next
#     end
#     renamed = rename(file)
#     if not renamed
#       if $verbose
#         puts green(file)
#       end
#     elsif renamed != file
#       unless $test
#         `mv "#{folder}/#{file}" "#{folder}/#{renamed}"`
#       end
#       puts "#{renamed} <= #{red(file)}"
#     end
#   end
# end

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

# returns array of unrecognized names
def process_entries(entries)
  unknown = []
  entries.each do |entry|
    if entry.parse()
      if entry.name_changed?()
        puts entry
        entry.rename()
      end
    else
      unknown += [entry]
    end
  end
  return unknown
end

# def rename(folder, file)
#   entry = Entry.new(folder, file)
#   entry.parse()
#   entry.new_filename()
# end

def copy_file(src_folder, dst_folder, file)
  entry = Entry.new(src_folder, dst_folder, file)
  entry.parse()
  if entry.keep?()
    entry.copy()
    # renamed = rename(dst, file)
    # dst_path = "#{dst}/#{renamed}"
    # if File.exist?(dst_path)
    #   puts "  exists #{dst_path}"
    #   src_size = File.size(src_path)
    #   dst_size = File.size(dst_path)
    #   if src_size == dst_size
    #     puts "  same size"
    #   elsif src_size > dst_size
    #     puts "  src=#{src_size} > dst=#{dst_size}"
    #     puts "  overwrite"
    #     unless $test
    #       `cp -n "#{src_path}" "#{dst}"`
    #     end
    #   else
    #     puts "  src=#{src_size} < dst=#{dst_size}"
    #     puts "  ignore"
    #   end
    # else
    #   puts "  copying #{file} to #{dst}"
    #   unless $test
    #     `cp -n "#{src_path}" "#{dst}"`
    #   end
    # end
  else
    puts "  skip #{file}"
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

def remove_if_src_not_exist(name)
  src = ""
end

def process_general(src_folder, dst, name, id)
  src = "#{src_folder}/#{name}"
  if File.exist?(src)
    if File.directory?(src)
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
  else # already processed
    puts "  src not exists"
    remove_torrent(id)
  end
end

def process_porn(to_folder, name, id)
  process_general(NORMAL_SRC, "/Users/johndoe/Raid2/porn/#{to_folder}", name, id)
end

def process_tvshow(tvshow, season, name, id)
  process_general(NORMAL_SRC, "#{TVSHOW_DST}/#{tvshow}/Season #{season}", name, id)
end

def process_tvshow_folder(tvshow, name, id)
  src_folder = "#{NORMAL_SRC}/#{name}"
  dst_folder = "#{TVSHOW_DST}/#{tvshow}"
  Dir.foreach(src_folder) do |file|
    next if [".", ".."].include?(file)
    renamed = file.gsub(/ Ep(\d\d) /, ' S01E\1 ')
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
      title = title.gsub('.', ' ')
      dst_folder = "/Users/johndoe/Movie2/#{title} (#{year})"
      unless File.exist?(dst_folder)
        `mkdir "#{dst_folder}"`
      end
      process_general(CP_SRC, dst_folder, name, id)
    else
      puts "  invalid year"
    end
  else
    puts "  unknown name"
  end
end

def process_existing_files
  unknown_entries = get_entries("/Users/johndoe/Raid2/porn/SexArt",
                                "/Users/johndoe/Raid2/porn/JoyMii")

  reduced = true
  i = 1
  while reduced
    old_length = unknown_entries.length
    puts "pass #{i} renamed"
    unknown_entries = process_entries(unknown_entries)
    reduced = unknown_entries.length < old_length
    i += 1
  end
  if unknown_entries.length > 0
    puts red("unrecognized files")
    puts unknown_entries
  end
end

$test = false
$verbose = false
ARGV.each do |arg|
  if arg == "-t" # test
    $test = true
  elsif arg == "-v" # verbose
    $verbose = true
  end
end

process_existing_files()

# find_names("/Users/johndoe/Raid2/porn/SexArt")
# find_names("/Users/johndoe/Raid2/porn/JoyMii")

# # $names = $names_dict.keys.sort.reverse
# if $verbose
#   puts $names
# end
# rename_files("/Users/johndoe/Raid2/porn/SexArt")
# rename_files("/Users/johndoe/Raid2/porn/JoyMii")

list = `transmission-remote --list`
list.split("\n").each do |line|
  id = line[0..3]
  status = line[57..67]
  name = line[70..-1]
  if status == "Finished   " ||
     status == "Stopped    "
    puts "#{cyan('processing')} #{line}"
    if name =~ /CSI.+S(\d\d)E\d\d\D/
      process_tvshow("CSI Crime Scene Investigation", $1, name, id)
    elsif name =~ /The.Big.Bang.Theory.S(\d\d)E\d\d\D/
      process_tvshow("The Big Bang Theory", $1, name, id)
    elsif name =~ /Carl Sagan's Cosmos/
      process_tvshow_folder("Cosmos", name, id)
    elsif name =~ /^(SexArt|WowGirls|X-Art|JoyMii)/i
      process_porn($1, name, id)
    else
      process_movie(name, id)
    end
  else
  end
end
