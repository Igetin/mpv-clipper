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
	new: (optType, displayText, value, opts) =>
		@optType = optType
		@displayText = displayText
		@opts = opts
		@value = 1
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

class EncodeOptionsPage extends Page
	new: (callback) =>
		@callback = callback
		@currentOption = 1
		
		crfOpts =
			step: 1
			min: -1
			altDisplayNames:
				[-1]: "disabled"

		profileOpts =
			possibleValues: [{p['name'], p['profile-desc']} for p in *encoding_profiles]

		-- This could be a dict instead of a array of pairs, but order isn't guaranteed
		-- by dicts on Lua.
		@options = {
			{"encoding_profile", Option("list", "Encoding profile", options.encoding_profile, profileOpts)},
			{"crf", Option("int", "CRF", options.crf, crfOpts)}
			-- {"audio", Option("bool", "Audio", options.audio)},
			-- {"burn_subtitles", Option("bool", "Burn subtitles", options.burn_subtitles)},
		}

		@keybinds =
			"LEFT": self\leftKey
			"RIGHT": self\rightKey
			"UP": self\prevOpt
			"DOWN": self\nextOpt
			"ENTER": self\confirmOpts
			"ESC": self\cancelOpts

	getCurrentOption: =>
		return @options[@currentOption][2]

	leftKey: =>
		(self\getCurrentOption!)\leftKey!
		self\draw!

	rightKey: =>
		(self\getCurrentOption!)\rightKey!
		self\draw!

	prevOpt: =>
		@currentOption = math.max(1, @currentOption - 1)
		self\draw!

	nextOpt: =>
		@currentOption = math.min(#@options, @currentOption + 1)
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
			opt\draw(ass, @currentOption == i)
		ass\append("\\N▲ / ▼: navigate\\N")
		ass\append("#{bold('ENTER:')} confirm options\\N")
		ass\append("#{bold('ESC:')} cancel\\N")
		mp.set_osd_ass(window_w, window_h, ass.text)
