class MainPage extends Page
	new: =>
		@keybinds =
			"c": self\crop
			"1": self\setStartTime
			"2": self\setEndTime
			"!": self\jumpToStartTime
			"@": self\jumpToEndTime
			"o": self\changeOptions
			"p": self\preview
			"e": self\encode
			"ESC": self\hide
			-- Gamepad controls. The d-pad, shoulder buttons and pause stay unbound
			-- here on purpose, so seeking/framestepping keeps working while the
			-- menu is open.
			"GAMEPAD_LEFT_STICK": self\crop
			"GAMEPAD_ACTION_LEFT": self\setStartTime
			"GAMEPAD_ACTION_UP": self\setEndTime
			"GAMEPAD_LEFT_TRIGGER": self\jumpToStartTime
			"GAMEPAD_RIGHT_TRIGGER": self\jumpToEndTime
			"GAMEPAD_RIGHT_STICK": self\changeOptions
			"GAMEPAD_ACTION_DOWN": self\preview
			"GAMEPAD_BACK": self\encode
			"GAMEPAD_ACTION_RIGHT": self\hide
			"GAMEPAD_START": self\hide
		@startTime = -1
		@endTime = -1
		@region = Region!

	setStartTime: =>
		@startTime = mp.get_property_number("time-pos")
		if @visible
			self\clear!
			self\draw!

	setEndTime: =>
		@endTime = mp.get_property_number("time-pos")
		if @visible
			self\clear!
			self\draw!

	jumpToStartTime: =>
		mp.set_property("time-pos", @startTime)

	jumpToEndTime: =>
		mp.set_property("time-pos", @endTime)

	setupStartAndEndTimes: =>
		if mp.get_property_native("duration")
			-- Note: there exists an option called rebase-start-time, which, when set to no,
			-- could cause the beginning of the video to not be at 0. Not sure how this
			-- would affect this code.
			@startTime = 0
			@endTime = mp.get_property_native("duration")
		else
			@startTime = -1
			@endTime = -1
		
		if @visible
			self\clear!
			self\draw!

	draw: =>
		window_w, window_h = mp.get_osd_size()
		ass = assdraw.ass_new()
		ass\new_event()
		self\setup_text(ass)
		status = {
			{"Profile", get_profile_desc(options.encoding_profile)},
			{"CRF", "#{options.crf}"},
			{"Tune", get_current_x264_tune_display!},
			{"Audio", get_current_audio_enabled_display!},
			{"Subtitles", get_current_burn_subtitles_display!},
			{"Start time", seconds_to_time_string(@startTime)},
			{"End time", seconds_to_time_string(@endTime)},
		}
		if @region.x > 0 and @region.y > 0
			status[#status + 1] = {"Crop", "#{@region.x}×#{@region.y}"}
		self\draw_instructions(ass, status)
		ass\new_event()
		self\setup_text_bottom(ass)
		self\draw_instructions(ass, {
			{"C / LS", "crop"},
			{"1 / X", "set start time"},
			{"2 / Y", "set end time"},
			{"! / LT", "jump to start time"},
			{"@ / RT", "jump to end time"},
			{"O / RS", "change options"},
			{"P / A", "preview"},
			{"E / View", "encode"},
			{"ESC / B / Menu", "close"},
		})
		mp.set_osd_ass(window_w, window_h, ass.text)
	
	show: =>
		super\show!

		emit_event("show-main-page")

	onUpdateCropRegion: (updated, newRegion) =>
		if updated
			@region = newRegion
		self\show!

	crop: =>
		self\hide!
		cropPage = CropPage(self\onUpdateCropRegion, @region)
		cropPage\show!

	onOptionsChanged: (updated) =>
		self\show!

	changeOptions: =>
		self\hide!
		encodeOptsPage = EncodeOptionsPage(self\onOptionsChanged)
		encodeOptsPage\show!

	onPreviewEnded: =>
		self\show!

	preview: =>
		self\hide!
		previewPage = PreviewPage(self\onPreviewEnded, @region, @startTime, @endTime)
		previewPage\show!

	encode: =>
		self\hide!
		if @startTime < 0
			message("No start time, aborting")
			return
		if @endTime < 0
			message("No end time, aborting")
			return
		if @startTime >= @endTime
			message("Start time is ahead of end time, aborting")
			return
		encode(@region, @startTime, @endTime)
