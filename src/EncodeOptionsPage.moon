class Option
	-- If optType is a "bool" or an "int", @value is the boolean/integer value of the option.
	-- Additionally, when optType is an "int":
	--     - opts.step specifies the step on which the values are changed.
	--     - opts.min specifies a minimum value for the option.
	--     - opts.max specifies a maximum value for the option.
	--     - opts.altDisplayNames is a int->string dict, which contains alternative display names
	--       for certain values.
	-- If optType is a "list", @value is the index of the current option, inside opts.possibleValues.
	-- opts.possibleValues is a array in the format
	-- {
	--		{value, displayValue}, -- Display value can be omitted.
	-- 		{value}
	-- }
	-- setValue will be called for the constructor argument.
	-- visibleCheckFn is a function to check for visibility, it can be used to hide options based on rules
	new: (optType, displayText, value, opts, visibleCheckFn) =>
		@optType = optType
		@displayText = displayText
		@opts = opts
		@value = 1
		@visibleCheckFn = visibleCheckFn
		self\setValue(value)

	-- Whether we have a "previous" option (for left key)
	hasPrevious: =>
		switch @optType
			when "bool"
				return true
			when "int"
				if @opts.min
					return @value > @opts.min
				else
					return true
			when "list"
				return @value > 1

	-- Analogous of hasPrevious.
	hasNext: =>
		switch @optType
			when "bool"
				return true
			when "int"
				if @opts.max
					return @value < @opts.max
				else
					return true
			when "list"
				return @value < #@opts.possibleValues

	leftKey: =>
		switch @optType
			when "bool"
				@value = not @value
			when "int"
				@value -= @opts.step
				if @opts.min and @opts.min > @value
					@value = @opts.min
			when "list"
				@value -= 1 if @value > 1

	rightKey: =>
		switch @optType
			when "bool"
				@value = not @value
			when "int"
				@value += @opts.step
				if @opts.max and @opts.max < @value
					@value = @opts.max
			when "list"
				@value += 1 if @value < #@opts.possibleValues

	getValue: =>
		switch @optType
			when "bool"
				return @value
			when "int"
				return @value
			when "list"
				{value, _} = @opts.possibleValues[@value]
				return value

	setValue: (value) =>
		switch @optType
			when "bool"
				@value = value
			when "int"
				-- TODO Should we obey opts.min/max? Or just trust the script to do the right thing(tm)?
				@value = value
			when "list"
				set = false
				for i, possiblePair in ipairs @opts.possibleValues
					{possibleValue, _} = possiblePair
					if possibleValue == value
						set = true
						@value = i
						break
				if not set
					msg.warn("Tried to set invalid value #{value} to #{@displayText} option.")

	getDisplayValue: =>
		switch @optType
			when "bool"
				return @value and "yes" or "no"
			when "int"
				if @opts.altDisplayNames and @opts.altDisplayNames[@value]
					return @opts.altDisplayNames[@value]
				else
					return "#{@value}"
			when "list"
				{value, displayValue} = @opts.possibleValues[@value]
				return displayValue or value

	draw: (ass, selected) =>
		if selected
			ass\append("#{bold(@displayText)}: ")
		else
			ass\append("#{@displayText}: ")
		-- left arrow unicode
		ass\append("◀ ") if self\hasPrevious!
		ass\append(self\getDisplayValue!)
		-- right arrow unicode
		ass\append(" ▶") if self\hasNext!
		ass\append("\\N")

	-- Check if this option should be visible by calling its visibleCheckFn
	optVisible: =>
		if self.visibleCheckFn == nil
			return true
		else
			return self.visibleCheckFn!

class EncodeOptionsPage extends Page
	new: (callback) =>
		@callback = callback
		@currentOption = 1
		-- TODO this shouldn't be here.
		scaleHeightOpts =
			possibleValues: {{-1, "no"}, {144}, {240}, {360}, {480}, {540}, {720}, {1080}, {1440}, {2160}}
		filesizeOpts =
			step: 250
			min: 0
			altDisplayNames:
				[0]: "0 (constant quality)"
		
		crfOpts =
			step: 1
			min: -1
			altDisplayNames:
				[-1]: "disabled"

		x264TuneOpts =
			possibleValues: {
				{"", "Profile default (#{get_profile_default_x264_tune(options.encoding_profile)})"}
				{"none", "No tune"}
				{"film"}
				{"animation"}
				{"grain"}
				{"stillimage"}
				{"psnr"}
				{"ssim"}
				{"fastdecode"}
				{"zerolatency"}
			}

		audioOpts =
			possibleValues: {
				{"", "Profile default (#{get_profile_default_audio_enabled(options.encoding_profile) and 'yes' or 'no'})"}
				{"yes", "yes"}
				{"no", "no"}
			}

		subtitleOpts =
			possibleValues: {
				{"", "Profile default (#{get_profile_default_subtitles_enabled(options.encoding_profile) and 'yes' or 'no'})"}
				{"yes", "yes"}
				{"no", "no"}
			}

		profileOpts =
			possibleValues: [{p['name'], p['profile-desc']} for p in *encoding_profiles]
		fpsOpts =
			possibleValues: {{-1, "source"}, {15}, {24}, {30}, {48}, {50}, {60}, {120}, {240}}

		-- I really dislike hardcoding this here, but, as said below, order in dicts isn't
		-- guaranteed, and we can't use the formats dict keys.
		-- formatIds = {"av1", "hevc", "webm-vp9", "avc", "avc-nvenc", "webm-vp8", "gif", "mp3", "raw"}
		-- formatOpts =
		-- 	possibleValues: [{fId, formats[fId].displayName} for fId in *formatIds]

		gifDitherOpts =
			possibleValues: {{0, "bayer_scale 0"}, {1, "bayer_scale 1"},
			{2, "bayer_scale 2"}, {3, "bayer_scale 3"}, {4, "bayer_scale 4"}, {5, "bayer_scale 5"}, {6, "sierra2_4a"}}

		-- This could be a dict instead of a array of pairs, but order isn't guaranteed
		-- by dicts on Lua.
		@options = {
			{"encoding_profile", Option("list", "Encoding profile", options.encoding_profile, profileOpts)},
			{"crf", Option("int", "CRF", options.crf, crfOpts)},
			{"x264_tune", Option("list", "x264 tune", options.x264_tune, x264TuneOpts)}
			{"audio_mode", Option("list", "Audio", options.audio_mode, audioOpts)}
			{"burn_subtitles", Option("list", "Burn subtitles", options.burn_subtitles, subtitleOpts)}
		}

		@keybinds =
			"LEFT": self\leftKey
			"RIGHT": self\rightKey
			"UP": self\prevOpt
			"DOWN": self\nextOpt
			"ENTER": self\confirmOpts
			"ESC": self\cancelOpts
			-- Gamepad controls. This page is fully modal, so overriding the
			-- d-pad seek bindings is fine here.
			"GAMEPAD_DPAD_LEFT": self\leftKey
			"GAMEPAD_DPAD_RIGHT": self\rightKey
			"GAMEPAD_DPAD_UP": self\prevOpt
			"GAMEPAD_DPAD_DOWN": self\nextOpt
			"GAMEPAD_ACTION_DOWN": self\confirmOpts
			"GAMEPAD_ACTION_RIGHT": self\cancelOpts
			"GAMEPAD_START": self\cancelOpts

	getCurrentOption: =>
		return @options[@currentOption][2]

	leftKey: =>
		(self\getCurrentOption!)\leftKey!
		self\syncDependentOptions!
		self\draw!

	rightKey: =>
		(self\getCurrentOption!)\rightKey!
		self\syncDependentOptions!
		self\draw!

	syncDependentOptions: =>
		currentPair = @options[@currentOption]
		return unless currentPair and currentPair[1] == "encoding_profile"

		for _, optPair in ipairs @options
			if optPair[1] == "x264_tune"
				tuneOption = optPair[2]
				tuneOption.opts.possibleValues[1][2] = "Profile default (#{get_profile_default_x264_tune((self\getCurrentOption!)\getValue! )})"
				if tuneOption\getValue! == ""
					tuneOption\setValue("")
			if optPair[1] == "audio_mode"
				audioOption = optPair[2]
				audioOption.opts.possibleValues[1][2] = "Profile default (#{get_profile_default_audio_enabled((self\getCurrentOption!)\getValue! ) and 'yes' or 'no'})"
				if audioOption\getValue! == ""
					audioOption\setValue("")
			if optPair[1] == "burn_subtitles"
				subtitleOption = optPair[2]
				subtitleOption.opts.possibleValues[1][2] = "Profile default (#{get_profile_default_subtitles_enabled((self\getCurrentOption!)\getValue! ) and 'yes' or 'no'})"
				if subtitleOption\getValue! == ""
					subtitleOption\setValue("")

	prevOpt: =>
		for i = @currentOption - 1, 1, -1
			if @options[i][2]\optVisible!
				@currentOption = i
				break
		self\draw!

	nextOpt: =>
		for i = @currentOption + 1, #@options
			if @options[i][2]\optVisible!
				@currentOption = i
				break
		self\draw!

	confirmOpts: =>
		for _, optPair in ipairs @options
			{optName, opt} = optPair
			-- Set the global options object.
			options[optName] = opt\getValue!
		self\hide!
		self.callback(true)

	cancelOpts: =>
		self\hide!
		self.callback(false)

	draw: =>
		window_w, window_h = mp.get_osd_size()
		ass = assdraw.ass_new()
		ass\new_event()
		self\setup_text(ass)
		ass\append("#{bold('Options:')}\\N\\N")
		for i, optPair in ipairs @options
			opt = optPair[2]
			if opt\optVisible!
				opt\draw(ass, @currentOption == i)
		ass\append("\\N▲ / ▼ / D-pad: navigate and change values\\N")
		ass\append("#{bold('ENTER / A:')} confirm options\\N")
		ass\append("#{bold('ESC / B:')} cancel\\N")
		mp.set_osd_ass(window_w, window_h, ass.text)
