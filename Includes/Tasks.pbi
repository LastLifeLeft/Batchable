Module Tasks
	EnableExplicit
	
	; Private Variale, structure and constants
	Global *CurrentSettings
	Global FontBold = FontID(LoadFont(#PB_Any, "Arial Black", 8, #PB_Font_HighQuality))
	Global NewMap GadgetMap()
	
	;{ Helpers
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; Fix color
		Macro FixColor(Color)
			RGB(Blue(Color), Green(Color), Red(Color))
		EndMacro
	CompilerElse
		Macro FixColor(Color)
			Color
		EndMacro
	CompilerEndIf
	
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; Set Alpha
		Macro SetAlpha(Color, Alpha)
			Alpha << 24 + Color
		EndMacro
	CompilerElse
		Macro SetAlpha(Color, Alpha) ; Not tested...
			Color << 8 + Alpha
		EndMacro
	CompilerEndIf
	
	Procedure SetTextColor(Gadget)
		SetGadgetColor(Gadget, #PB_Gadget_BackColor, MainWindow::TaskContainerBackColor)
		SetGadgetColor(Gadget, #PB_Gadget_FrontColor, MainWindow::TaskContainerFrontColor)
	EndProcedure
	
	Procedure SetTitleColor(Gadget)
		SetTextColor(Gadget)
		SetGadgetFont(Gadget, FontBold)
	EndProcedure
	
	Procedure SetComboColor(Combo)
		SetGadgetColor(Combo, UITK::#Color_Parent, SetAlpha(UITK::WindowGetColor(MainWindow::Window, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(Combo, UITK::#Color_Back_Warm, SetAlpha(UITK::WindowGetColor(MainWindow::Window, UITK::#Color_Back_Cold), 255))
	EndProcedure
	
	Procedure SetTrackBarColor(TrackBar)
		SetGadgetColor(TrackBar, UITK::#Color_Parent, SetAlpha(MainWindow::TaskContainerBackColor, 255))
		SetGadgetColor(TrackBar, UITK::#Color_Shade_Warm, SetAlpha(GetGadgetColor(TrackBar, UITK::#Color_Line_Cold), 255))
		SetGadgetColor(TrackBar, UITK::#Color_Line_Cold, SetAlpha(MainWindow::TaskContainerFrontColor, 200))
	EndProcedure
	
	Macro FillList(TaskName)
		Task(#Task_#TaskName)\IconID = ImageID(CatchImage(#PB_Any, ?TaskName))
		Task(#Task_#TaskName)\Populate = @TaskName#_Populate()
		Task(#Task_#TaskName)\CleanUp = @TaskName#_CleanUp()
		Task(#Task_#TaskName)\DefaultSettings = AllocateMemory(SizeOf(TaskName#_Settings))
	EndMacro
	;}
	
	;{ Alpha Threshold
	Structure AlphaThreshold_Settings
		Threshold.a
	EndStructure
	
	Procedure AlphaThreshold_TrackBarHandler()
		Protected *Settings.AlphaThreshold_Settings = *CurrentSettings
		*Settings\Threshold = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure AlphaThreshold_Populate(*Settings.AlphaThreshold_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Threshold Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "Threshold value:")
		SetTitleColor(GadgetMap("Threshold Text"))
		
		GadgetMap("Threshold Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 40, 0, 255, UITK::#Trackbar_ShowState)
		SetTrackBarColor(GadgetMap("Threshold Trackbar"))
		BindGadgetEvent(GadgetMap("Threshold Trackbar"), @AlphaThreshold_TrackBarHandler(), #PB_EventType_Change)
		SetGadgetState(GadgetMap("Threshold Trackbar"), *Settings\Threshold)
	EndProcedure
	
	Procedure AlphaThreshold_CleanUp()
		FreeGadget(GadgetMap("Threshold Text"))
		UnbindGadgetEvent(GadgetMap("Threshold Trackbar"), @AlphaThreshold_TrackBarHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Threshold Trackbar"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_AlphaThreshold)\Name = "Alpha Threshold"
	Task(#Task_AlphaThreshold)\Description = "Remove gradation to alpha transparency according to a given value."
	Task(#Task_AlphaThreshold)\Type = MainWindow::#TaskType_Colors
	FillList(AlphaThreshold)
	PokeA(Task(#Task_AlphaThreshold)\DefaultSettings, 128)
	;}
	
	;{ Channel Swap
	Structure ChannelSwap_Settings
		Null.a
	EndStructure
	
	Procedure ChannelSwap_Populate(*Settings.ChannelSwap_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Red Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "Channel used for the red Channel")
		SetTitleColor(GadgetMap("Red Text"))
		
		
		GadgetMap("Green Text") = TextGadget(#PB_Any, #Margin, #Margin + 60, MainWindow::TaskContainerGadgetWidth, 15, "Channel used for the green Green")
		SetTitleColor(GadgetMap("Green Text"))
		
		
		GadgetMap("Blue Text") = TextGadget(#PB_Any, #Margin, #Margin + 120, MainWindow::TaskContainerGadgetWidth, 15, "Channel used for the blue Channel")
		SetTitleColor(GadgetMap("Blue Text"))
		
		
		GadgetMap("Alpha Text") = TextGadget(#PB_Any, #Margin, #Margin + 180, MainWindow::TaskContainerGadgetWidth, 15, "Channel used for the alpha Channel")
		SetTitleColor(GadgetMap("Alpha Text"))
		
		
	EndProcedure
	
	Procedure ChannelSwap_CleanUp()
		FreeGadget(GadgetMap("Red Text"))
		FreeGadget(GadgetMap("Green Text"))
		FreeGadget(GadgetMap("Blue Text"))
		FreeGadget(GadgetMap("Alpha Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_ChannelSwap)\Name = "Channel Swap"
	Task(#Task_ChannelSwap)\Description = "Change each color channels assignation."
	Task(#Task_ChannelSwap)\Type = MainWindow::#TaskType_Colors
	FillList(ChannelSwap)
	;}
	
	;{ Channel Displacement
	Structure ChannelDisplacement_Settings
		Null.a
	EndStructure
	
	Procedure ChannelDisplacement_Populate(*Settings.ChannelDisplacement_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure ChannelDisplacement_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_ChannelDisplacement)\Name = "Channel Displacement"
	Task(#Task_ChannelDisplacement)\Description = "Move around each color channel individually."
	Task(#Task_ChannelDisplacement)\Type = MainWindow::#TaskType_Colors
	FillList(ChannelDisplacement)
	;}
	
	;{ Invert Color
	Structure Invertcolor_Settings
		Null.a
	EndStructure
	
	Procedure Invertcolor_Populate(*Settings.Invertcolor_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Invertcolor_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_InvertColor)\Name = "Invert Color"
	Task(#Task_InvertColor)\Description = "Reverse the colors, black becomes white, white becomes black."
	Task(#Task_InvertColor)\Type = MainWindow::#TaskType_Colors
	FillList(Invertcolor)
	;}
	
	;{ Black & White
	Structure BlackAndWhite_Settings
		Null.a
	EndStructure
	
	Procedure BlackAndWhite_Populate(*Settings.BlackAndWhite_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure BlackAndWhite_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_BlackAndWhite)\Name = "Black & White"
	Task(#Task_BlackAndWhite)\Description = "Convert all colors to black and white (greyscale)."
	Task(#Task_BlackAndWhite)\Type = MainWindow::#TaskType_Colors
	FillList(BlackAndWhite)
	;}
	
	;{ Color Balance
	Structure ColorBalance_Settings
		Red.a
		Green.a
		Blue.a
	EndStructure
	
	Procedure ColorBalance_RedTrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		*Settings\Red = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_GreenTrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		*Settings\Green = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_BlueTrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		*Settings\Blue = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_Populate(*Settings.ColorBalance_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Red Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "Red:")
		SetTitleColor(GadgetMap("Red Text"))
		GadgetMap("Red Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 40, 0, 255, UITK::#Trackbar_ShowState)
		SetGadgetColor(GadgetMap("Red Trackbar"), UITK::#Color_Special3_Cold, SetAlpha(UITK::WindowGetColor(MainWindow::Window, UITK::#Color_Special1_Cold), 255))
		SetTrackBarColor(GadgetMap("Red Trackbar"))
		SetGadgetState(GadgetMap("Red Trackbar"), *Settings\Red)
		BindGadgetEvent(GadgetMap("Red Trackbar"), @ColorBalance_RedTrackBarHandler(), #PB_EventType_Change)
		
		GadgetMap("Green Text") = TextGadget(#PB_Any, #Margin, #Margin + 75, MainWindow::TaskContainerGadgetWidth, 15, "Green:")
		SetTitleColor(GadgetMap("Green Text"))
		GadgetMap("Green Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 95, MainWindow::TaskContainerGadgetWidth, 40, 0, 255, UITK::#Trackbar_ShowState)
		SetGadgetColor(GadgetMap("Green Trackbar"), UITK::#Color_Special3_Cold, SetAlpha(UITK::WindowGetColor(MainWindow::Window, UITK::#Color_Special2_Cold), 255))
		SetTrackBarColor(GadgetMap("Green Trackbar"))
		SetGadgetState(GadgetMap("Green Trackbar"), *Settings\Green)
		BindGadgetEvent(GadgetMap("Green Trackbar"), @ColorBalance_GreenTrackBarHandler(), #PB_EventType_Change)
		
		GadgetMap("Blue Text") = TextGadget(#PB_Any, #Margin, #Margin + 150, MainWindow::TaskContainerGadgetWidth, 15, "Blue:")
		SetTitleColor(GadgetMap("Blue Text"))
		GadgetMap("Blue Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 170, MainWindow::TaskContainerGadgetWidth, 40, 0, 255, UITK::#Trackbar_ShowState)
		SetTrackBarColor(GadgetMap("Blue Trackbar"))
		SetGadgetState(GadgetMap("Blue Trackbar"), *Settings\Blue)
		BindGadgetEvent(GadgetMap("Blue Trackbar"), @ColorBalance_BlueTrackBarHandler(), #PB_EventType_Change)
	EndProcedure
	
	Procedure ColorBalance_CleanUp()
		FreeGadget(GadgetMap("Red Text"))
		FreeGadget(GadgetMap("Green Text"))
		FreeGadget(GadgetMap("Blue Text"))
		
		UnbindGadgetEvent(GadgetMap("Red Trackbar"), @ColorBalance_RedTrackBarHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Red Trackbar"))
		UnbindGadgetEvent(GadgetMap("Green Trackbar"), @ColorBalance_GreenTrackBarHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Green Trackbar"))
		UnbindGadgetEvent(GadgetMap("Blue Trackbar"), @ColorBalance_BlueTrackBarHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Blue Trackbar"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_ColorBalance)\Name = "Color Balance"
	Task(#Task_ColorBalance)\Description = "Change the global adjustment of the intensities of the colors."
	Task(#Task_ColorBalance)\Type = MainWindow::#TaskType_Colors
	FillList(ColorBalance)
	PokeA(Task(#Task_ColorBalance)\DefaultSettings, 255)
	PokeA(Task(#Task_ColorBalance)\DefaultSettings + SizeOf(Ascii), 255)
	PokeA(Task(#Task_ColorBalance)\DefaultSettings + SizeOf(Ascii) * 2, 255)
	;}
	
	;{ Posterization
	Structure Posterization_Settings
		Null.a
	EndStructure
	
	Procedure Posterization_Populate(*Settings.Posterization_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Posterization_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Posterization)\Name = "Posterization"
	Task(#Task_Posterization)\Description = "Reduce the range of colors used to fewer tones."
	Task(#Task_Posterization)\Type = MainWindow::#TaskType_Colors
	FillList(Posterization)
	;}
	
	;{ Outline
	Structure Outline_Settings
		Null.a
	EndStructure
	
	Procedure Outline_Populate(*Settings.Outline_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Outline_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Outline)\Name = "Outline"
	Task(#Task_Outline)\Description = "Add an outline around objects."
	Task(#Task_Outline)\Type = MainWindow::#TaskType_Transformation
	FillList(Outline)
	;}
	
	;{ Trim Border
	Structure TrimImage_Settings
		Null.a
	EndStructure
	
	Procedure TrimImage_Populate(*Settings.TrimImage_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure TrimImage_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_TrimImage)\Name = "Trim Border"
	Task(#Task_TrimImage)\Description = "Remove the transparent pixels around the images."
	Task(#Task_TrimImage)\Type = MainWindow::#TaskType_Transformation
	FillList(TrimImage)
	;}
	
	;{ Resize
	Structure Resize_Settings
		Null.a
	EndStructure
	
	Procedure Resize_Populate(*Settings.Resize_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "Target Size")
		SetTitleColor(GadgetMap("Title Text"))
		
		GadgetMap("Algorithm Text") = TextGadget(#PB_Any, #Margin, #Margin + 50, MainWindow::TaskContainerGadgetWidth, 15, "Algorithm used")
		SetTitleColor(GadgetMap("Algorithm Text"))
		
		GadgetMap("Algorithm Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 70, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Algorithm Combo"))
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "Automatic (chosen for each image)")
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "Nearest Neighbor")
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "Super Sampling")
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "Bicubic")
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "Bilinear")
		SetGadgetState(GadgetMap("Algorithm Combo"), 0)
		
		GadgetMap("Padding Text") = TextGadget(#PB_Any, #Margin, #Margin + 115, MainWindow::TaskContainerGadgetWidth, 15, "Aspect ratio handling")
		SetTitleColor(GadgetMap("Padding Text"))
		
		GadgetMap("Padding Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 135, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Padding Combo"))
		AddGadgetItem(GadgetMap("Padding Combo"), -1, "Scale Inner (LetterBoxing)")
		AddGadgetItem(GadgetMap("Padding Combo"), -1, "Scale Inner (Crop)")
		AddGadgetItem(GadgetMap("Padding Combo"), -1, "Scale Outer")
		AddGadgetItem(GadgetMap("Padding Combo"), -1, "Stretch")
		SetGadgetState(GadgetMap("Padding Combo"), 0)
	EndProcedure
	
	Procedure Resize_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Algorithm Text"))
		FreeGadget(GadgetMap("Algorithm Combo"))
		FreeGadget(GadgetMap("Padding Text"))
		FreeGadget(GadgetMap("Padding Combo"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Resize)\Name = "Resize"
	Task(#Task_Resize)\Description = "Resize to target size using various algorithms."
	Task(#Task_Resize)\Type = MainWindow::#TaskType_Transformation
	FillList(Resize)
	;}
	
	;{ Blur
	Structure Blur_Settings
		Null.a
	EndStructure
	
	Procedure Blur_TrackBarHandler()
		Protected *Settings.Blur_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Blur_Populate(*Settings.Blur_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Blur_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Blur)\Name = "Blur"
	Task(#Task_Blur)\Description = "Apply a gaussian blur on the images."
	Task(#Task_Blur)\Type = MainWindow::#TaskType_Transformation
	FillList(Blur)
	;}
	
	;{ Watermark
	Structure Watermark_Settings
		Null.a
	EndStructure
	
	Procedure Watermark_Populate(*Settings.Watermark_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Watermark_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Watermark)\Name = "Watermark"
	Task(#Task_Watermark)\Description = "Overlay the images with a text or another image."
	Task(#Task_Watermark)\Type = MainWindow::#TaskType_Transformation
	FillList(Watermark)
	;}
	
	;{ RotSprite
	Structure RotSprite_Settings
		Angle.w
	EndStructure
	
	Procedure RotSprite_TrackBarHandler()
		Protected *Settings.RotSprite_Settings = *CurrentSettings
		*Settings\Angle = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure RotSprite_Populate(*Settings.RotSprite_Settings)
		*CurrentSettings = *Settings
		GadgetMap("Angle Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "Rotation angle:")
		SetTitleColor(GadgetMap("Angle Text"))
		
		GadgetMap("Angle Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 40, 0, 360, UITK::#Trackbar_ShowState)
		BindGadgetEvent(GadgetMap("Angle Trackbar"), @RotSprite_TrackBarHandler(), #PB_EventType_Change)
		
		SetGadgetState(GadgetMap("Angle Trackbar"), *Settings\Angle)
		SetTrackBarColor(GadgetMap("Angle Trackbar"))
	EndProcedure
	
	Procedure RotSprite_CleanUp()
		FreeGadget(GadgetMap("Angle Text"))
		FreeGadget(GadgetMap("Angle Trackbar"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Rotsprite)\Name = "Rotsprite"
	Task(#Task_Rotsprite)\Description = "Rotates images using the Rotsprite algorithm by Xenowhirl."
	Task(#Task_Rotsprite)\Type = MainWindow::#TaskType_PixelArt
	FillList(RotSprite)
	PokeW(Task(#Task_Rotsprite)\DefaultSettings, 0)
	;}
	
	;{ Pixel-art upscale
	Structure PixelArtUpscale_Settings
		Scale.a
		Algorithm.a
	EndStructure
	
	Procedure PixelArtUpscale_TrackBarHandler()
		Protected *Settings.PixelArtUpscale_Settings = *CurrentSettings
		*Settings\Scale = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure PixelArtUpscale_ComboHandler()
		Protected *Settings.PixelArtUpscale_Settings = *CurrentSettings
		*Settings\Algorithm = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure PixelArtUpscale_Populate(*Settings.PixelArtUpscale_Settings)
		Protected Width
		*CurrentSettings = *Settings
		Width = Round((MainWindow::TaskContainerGadgetWidth - 3 * #Margin) / 4, #PB_Round_Nearest)
		
		GadgetMap("Scale Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "Scale:")
		SetTitleColor(GadgetMap("Scale Text"))
		
		GadgetMap("Scale Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 40, 2, 5)
		SetTrackBarColor(GadgetMap("Scale Trackbar"))
		AddGadgetItem(GadgetMap("Scale Trackbar"), 2, "x2")
		AddGadgetItem(GadgetMap("Scale Trackbar"), 3, "x3")
		AddGadgetItem(GadgetMap("Scale Trackbar"), 4, "x4")
		AddGadgetItem(GadgetMap("Scale Trackbar"), 5, "x5")
		SetGadgetState(GadgetMap("Scale Trackbar"), *Settings\Scale)
		BindGadgetEvent(GadgetMap("Scale Trackbar"), @PixelArtUpscale_TrackBarHandler(), #PB_EventType_Change)
		
		GadgetMap("Algorithm Text") = TextGadget(#PB_Any, #Margin, #Margin + 75, MainWindow::TaskContainerGadgetWidth, 15, "Algorithm:")
		SetTitleColor(GadgetMap("Algorithm Text"))
		GadgetMap("Algorithm Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 95, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Algorithm Combo"))
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "xBR")
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "HQx")
		AddGadgetItem(GadgetMap("Algorithm Combo"), -1, "Kopf–Lischinski ")
		SetGadgetState(GadgetMap("Algorithm Combo"), *Settings\Algorithm)
		BindGadgetEvent(GadgetMap("Algorithm Combo"), @PixelArtUpscale_ComboHandler(), #PB_EventType_Change)
		
	EndProcedure
	
	Procedure PixelArtUpscale_CleanUp()
		FreeGadget(GadgetMap("Scale Text"))
		UnbindGadgetEvent(GadgetMap("Scale Trackbar"), @PixelArtUpscale_TrackBarHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Scale Trackbar"))
		
		FreeGadget(GadgetMap("Algorithm Text"))
		UnbindGadgetEvent(GadgetMap("Algorithm Combo"), @PixelArtUpscale_ComboHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Algorithm Combo"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_PixelArtUpscale)\Name = "Pixel-art upscale"
	Task(#Task_PixelArtUpscale)\Description = "Upscale sprites using various algorithms."
	Task(#Task_PixelArtUpscale)\Type = MainWindow::#TaskType_PixelArt
	FillList(PixelArtUpscale)
	PokeA(Task(#Task_PixelArtUpscale)\DefaultSettings, 2)
	;}
	
	;{ Save as gif
	Structure SaveGif_Settings
		Null.a
	EndStructure
	
	Procedure SaveGif_Populate(*Settings.SaveGif_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure SaveGif_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_SaveGif)\Name = "Save as gif"
	Task(#Task_SaveGif)\Description = "Merge all the images in a single gif file."
	Task(#Task_SaveGif)\Type = MainWindow::#TaskType_Other
	FillList(SaveGif)
	;}
	
	;{ Save options
	Structure Save_Settings
		Null.a
	EndStructure
	
	Procedure Save_Populate(*Settings.Save_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Save_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Save)\Name = "Save options"
	Task(#Task_Save)\Description = "Set up how the results should be written on the disk."
	Task(#Task_Save)\Type = MainWindow::#TaskType_Other
	FillList(Save)
	;}
	
	DataSection ;{
		BlackAndWhite:
		IncludeBinary "..\Media\Tinified\Black & White.png"
		
		Blur:
		IncludeBinary "..\Media\Tinified\Blur.png"
		
		ChannelDisplacement:
		IncludeBinary "..\Media\Tinified\Channel Displacement.png"
		
		ChannelSwap:
		IncludeBinary "..\Media\Tinified\Channel swap.png"
		
		ColorBalance:
		IncludeBinary "..\Media\Tinified\Color Balance.png"
		
		SaveGif:
		IncludeBinary "..\Media\Tinified\Gif.png"
		
		Invertcolor:
		IncludeBinary "..\Media\Tinified\Invert color.png"
		
		Outline:
		IncludeBinary "..\Media\Tinified\Outline.png"
		
		PixelArtUpscale:
		IncludeBinary "..\Media\Tinified\Pixel Upscale.png"
		
		Posterization:
		IncludeBinary "..\Media\Tinified\Posterization.png"
		
		Resize:
		IncludeBinary "..\Media\Tinified\Resize.png"
		
		RotSprite:
		IncludeBinary "..\Media\Tinified\RotSprite.png"
		
		Save:
		IncludeBinary "..\Media\Tinified\Save.png"
		
		AlphaThreshold:
		IncludeBinary "..\Media\Tinified\Threshold.png"
		
		TrimImage:
		IncludeBinary "..\Media\Tinified\Trim.png"
		
		Watermark:
		IncludeBinary "..\Media\Tinified\Watermark.png"
		
	
	EndDataSection ;}
EndModule

























; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 212
; Folding = BQAAAAAAAAAw
; EnableXP