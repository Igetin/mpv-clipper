bold = (text) ->
	"{\\b1}#{text}{\\b0}"

-- OSD message, using ass.
message = (text, duration) ->
	ass = mp.get_property_osd("osd-ass-cc/0")
	-- wanted to set font size here, but it's completely unrelated to the font
	-- size in set_osd_ass.
	ass ..= text
	mp.osd_message(ass, duration or options.message_duration)

append = (a, b) ->
	for _, val in ipairs b
		a[#a+1] = val
	return a

seconds_to_time_string = (seconds, no_ms, full) ->
	if seconds < 0
		return "unknown"
	ret = ""
	ret = string.format(".%03d", seconds * 1000 % 1000) unless no_ms
	ret = string.format("%02d:%02d%s", math.floor(seconds / 60) % 60, math.floor(seconds) % 60, ret)
	if full or seconds > 3600
		ret = string.format("%d:%s", math.floor(seconds / 3600), ret)
	ret

seconds_to_path_element = (seconds, no_ms, full) ->
	time_string = seconds_to_time_string(seconds, no_ms, full)
	-- Needed for Windows (and maybe for Linux? idk)
	time_string, _ = time_string\gsub(":", ".")
	return time_string

file_exists = (name) ->
	info, err = utils.file_info(name)
	if info ~= nil
		return true
	return false

expand_properties = (text, magic="$") ->
	for prefix, raw, prop, colon, fallback, closing in text\gmatch("%" .. magic .. "{([?!]?)(=?)([^}:]*)(:?)([^}]*)(}*)}")
		local err
		local prop_value
		local compare_value
		original_prop = prop
		get_property = mp.get_property_osd

		if raw == "="
			get_property = mp.get_property

		if prefix ~= ""
			for actual_prop, compare in prop\gmatch("(.-)==(.*)")
				prop = actual_prop
				compare_value = compare

		if colon == ":"
			prop_value, err = get_property(prop, fallback)
		else
			prop_value, err = get_property(prop, "(error)")
		prop_value = tostring(prop_value)

		if prefix == "?"
			if compare_value == nil
				prop_value = err == nil and fallback .. closing or ""
			else
				prop_value = prop_value == compare_value and fallback .. closing or ""
			prefix = "%" .. prefix
		elseif prefix == "!"
			if compare_value == nil
				prop_value = err ~= nil and fallback .. closing or ""
			else
				prop_value = prop_value ~= compare_value and fallback .. closing or ""
		else
			prop_value = prop_value .. closing

		if colon == ":"
			text, _ = text\gsub("%" .. magic .. "{" .. prefix .. raw .. original_prop\gsub("%W", "%%%1") .. ":" .. fallback\gsub("%W", "%%%1") .. closing .. "}", expand_properties(prop_value))
		else
			text, _ = text\gsub("%" .. magic .. "{" .. prefix .. raw .. original_prop\gsub("%W", "%%%1") .. closing .. "}", prop_value)

	return text

sanitize_path_component = (component) ->
	-- Remove invalid chars from each path component.
	-- Windows: < > : " / \ | ? *
	-- Linux: /
	sanitized, _ = component\gsub("[<>:\"/\\|?*]", "")
	if sanitized == "." or sanitized == ".."
		return "_"
	return sanitized

join_relative_path = (parts) ->
	path = parts[1]
	for i = 2, #parts
		path = utils.join_path(path, parts[i])
	return path

format_filename = (startTime, endTime, extension) ->
	replaceFirst =
		"%%mp": "%%mH.%%mM.%%mS"
		"%%mP": "%%mH.%%mM.%%mS.%%mT"
		"%%p": "%%wH.%%wM.%%wS"
		"%%P": "%%wH.%%wM.%%wS.%%wT"
	replaceTable =
		"%%wH": string.format("%02d", math.floor(startTime/(60*60)))
		"%%wh": string.format("%d", math.floor(startTime/(60*60)))
		"%%wM": string.format("%02d", math.floor(startTime/60%60))
		"%%wm": string.format("%d", math.floor(startTime/60))
		"%%wS": string.format("%02d", math.floor(startTime%60))
		"%%ws": string.format("%d", math.floor(startTime))
		"%%wf": string.format("%s", startTime)
		"%%wT": string.sub(string.format("%.3f", startTime%1), 3)
		"%%mH": string.format("%02d", math.floor(endTime/(60*60)))
		"%%mh": string.format("%d", math.floor(endTime/(60*60)))
		"%%mM": string.format("%02d", math.floor(endTime/60%60))
		"%%mm": string.format("%d", math.floor(endTime/60))
		"%%mS": string.format("%02d", math.floor(endTime%60))
		"%%ms": string.format("%d", math.floor(endTime))
		"%%mf": string.format("%s", endTime)
		"%%mT": string.sub(string.format("%.3f", endTime%1), 3)
		"%%f": mp.get_property("filename")
		"%%F": mp.get_property("filename/no-ext")
		"%%s": seconds_to_path_element(startTime)
		"%%S": seconds_to_path_element(startTime, true)
		"%%e": seconds_to_path_element(endTime)
		"%%E": seconds_to_path_element(endTime, true)
		"%%T": mp.get_property("media-title")
		"%%R": (options.scale_height != -1) and "-#{options.scale_height}p" or "-#{mp.get_property_native('height')}p"
		-- "%%mb": options.target_filesize/1000
		"%%t%%": "%%"
	filename = options.output_template

	for format, value in pairs replaceFirst
		filename, _ = filename\gsub(format, value)
	for format, value in pairs replaceTable
		filename, _ = filename\gsub(format, value)

	if mp.get_property_bool("demuxer-via-network", false)
		filename, _ = filename\gsub("%%X{([^}]*)}", "%1")
		filename, _ = filename\gsub("%%x", "")
	else
		x = string.gsub(mp.get_property("stream-open-filename", ""), string.gsub(mp.get_property("filename", ""), "%W", "%%%1") .. "$", "")
		filename, _ = filename\gsub("%%X{[^}]*}", x)
		filename, _ = filename\gsub("%%x", x)

	filename = expand_properties(filename, "%")

	for format in filename\gmatch("%%t([aAbBcCdDeFgGhHIjmMnprRStTuUVwWxXyYzZ])")
		filename, _ = filename\gsub("%%t" .. format, os.date("%" .. format))

	parts = {}
	for part in filename\gmatch("[^/\\]+")
		sanitized = sanitize_path_component(part)
		parts[#parts + 1] = sanitized if sanitized != ""

	if #parts == 0
		fallback = sanitize_path_component(mp.get_property("filename/no-ext") or "clip")
		parts[1] = fallback != "" and fallback or "clip"

	parts[#parts] = "#{parts[#parts]}.#{extension}"

	return join_relative_path(parts)

parse_directory = (dir) ->
	home_dir = os.getenv("HOME")
	if not home_dir
		-- Windows home dir is obtained by USERPROFILE, or, if it fails, HOMEDRIVE + HOMEPATH
		home_dir = os.getenv("USERPROFILE")

	if not home_dir
		drive = os.getenv("HOMEDRIVE")
		path = os.getenv("HOMEPATH")
		if drive and path
			home_dir = utils.join_path(drive, path)
		else
			msg.warn("Couldn't find home dir.")
			home_dir = ""
	dir, _ = dir\gsub("^~", home_dir)
	return dir

-- from stats.lua
is_windows = type(package) == "table" and type(package.config) == "string" and package.config\sub(1, 1) == "\\"

trim = (s) ->
	return s\match("^%s*(.-)%s*$")

get_null_path = ->
	if file_exists("/dev/null")
		return "/dev/null"
	return "NUL"

run_subprocess = (params) ->
	res = utils.subprocess(params)
	msg.verbose("Command stdout: ")
	msg.verbose(res.stdout)
	if res.status != 0
		msg.verbose("Command failed! Reason: ", res.error, " Killed by us? ", res.killed_by_us and "yes" or "no")
		return false
	return true

ensure_directory_exists = (dir) ->
	return true if dir == nil or dir == ""
	info, _ = utils.file_info(dir)
	return true if info != nil
	command = if is_windows
		{"cmd", "/C", "mkdir", dir}
	else
		{"mkdir", "-p", dir}
	run_subprocess({args: command, cancellable: false})

shell_escape = (args) ->
	ret = {}
	for i,a in ipairs(args)
		s = tostring(a)
		if string.match(s, "[^A-Za-z0-9_/:=-]")
			-- Single quotes for UNIX, double quotes for Windows.
			if is_windows
				s = '"'..string.gsub(s, '"', '"\\""')..'"'
			else
				s = "'"..string.gsub(s, "'", "'\\''").."'"
		table.insert(ret,s)
	concat = table.concat(ret, " ")
	if is_windows
		-- Add a second set of double-quotes because idk it works
		concat = '"' .. concat .. '"'
	return concat

run_subprocess_popen = (command_line) ->
	command_line_string = shell_escape(command_line)
	-- Redirect stderr to stdout, because for some reason
	-- the progress is outputted to stderr???
	command_line_string ..= " 2>&1"
	msg.verbose("run_subprocess_popen: running #{command_line_string}")
	return io.popen(command_line_string)

calculate_scale_factor = () ->
	baseResY = 720
	osd_w, osd_h = mp.get_osd_size()
	return osd_h / baseResY

should_display_progress = () ->
	if options.display_progress == "auto"
		return not is_windows
	return options.display_progress

reverse = (list) ->
	[element for element in *list[#list, 1, -1]]

get_pass_logfile_path = (encode_out_path) ->
	"#{encode_out_path}-video-pass1.log"

starts_with = (str, start) ->
   return string.sub(str, 1, #start) == start

encoding_profiles = [p for p in *(mp.get_property_native('profile-list')) when starts_with(p['name'], 'enc-')]

get_encoding_profile = (name) ->
	for p in *encoding_profiles
		if name == p['name']
			return p

get_encoding_profile_option = (name, key) ->
	profile = get_encoding_profile(name)
	return nil unless profile and profile['options']

	for option in *profile['options']
		if option['key'] == key
			return option['value']

get_key_value_list_entry = (value, key) ->
	return nil unless value

	for item in string.gmatch(value, "[^,]+")
		if starts_with(item, "#{key}=")
			return string.sub(item, #key + 2)

get_encoding_profile_codec_option = (name, key) ->
	directValue = get_encoding_profile_option(name, key)
	return directValue if directValue

	profile = get_encoding_profile(name)
	return nil unless profile and profile['options']

	for option in *profile['options']
		continue unless option['value']

		if option['key'] == 'ovcopts'
			parsedValue = get_key_value_list_entry(option['value'], key)
			return parsedValue if parsedValue

		if option['key'] == 'ovcopts-add' and starts_with(option['value'], "#{key}=")
			return string.sub(option['value'], #key + 2)

get_profile_default_x264_tune = (name) ->
	get_encoding_profile_codec_option(name, 'tune') or 'animation'

get_profile_default_audio_codec = (name) ->
	codec = get_encoding_profile_option(name, 'oac')
	return nil if codec == 'no'
	codec

get_profile_default_audio_enabled = (name) ->
	audioEnabled = get_encoding_profile_option(name, 'audio')
	return false if audioEnabled == 'no'

	selectedAudio = get_encoding_profile_option(name, 'aid')
	return false if selectedAudio == 'no'

	codec = get_encoding_profile_option(name, 'oac')
	return false if codec == 'no'

	true

get_current_x264_tune = ->
	if options.x264_tune == "none"
		return nil
	if options.x264_tune and options.x264_tune != ""
		return options.x264_tune
	get_profile_default_x264_tune(options.encoding_profile)

get_current_x264_tune_display = ->
	get_current_x264_tune! or "none"

get_current_audio_enabled = ->
	if options.audio_mode == 'no'
		return false
	if options.audio_mode == 'yes'
		return true
	get_profile_default_audio_enabled(options.encoding_profile)

get_current_audio_enabled_display = ->
	get_current_audio_enabled! and 'yes' or 'no'

get_profile_desc = (name) ->
	for p in *encoding_profiles
		if name == p['name']
			return p['profile-desc']
