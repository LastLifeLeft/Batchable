﻿Module Tasks
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
		
		GadgetMap("Threshold Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "Threshold value:")
		SetTitleColor(GadgetMap("Threshold Text"))
		
		GadgetMap("Threshold Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 40, 0, 255, UITK::#Trackbar_ShowState | UITK::#DarkMode)
		BindGadgetEvent(GadgetMap("Threshold Trackbar"), @AlphaThreshold_TrackBarHandler(), #PB_EventType_Change)
		
		SetGadgetState(GadgetMap("Threshold Trackbar"), *Settings\Threshold)
		AddGadgetItem(GadgetMap("Threshold Trackbar"), 0, "")
		AddGadgetItem(GadgetMap("Threshold Trackbar"), 255, "")
		SetGadgetColor(GadgetMap("Threshold Trackbar"), UITK::#Color_Parent, SetAlpha(MainWindow::TaskContainerBackColor, 255))
		SetGadgetColor(GadgetMap("Threshold Trackbar"), UITK::#Color_Shade_Warm, SetAlpha(GetGadgetColor(GadgetMap("Threshold Trackbar"), UITK::#Color_Line_Cold), 255))
		SetGadgetColor(GadgetMap("Threshold Trackbar"), UITK::#Color_Line_Cold, SetAlpha(MainWindow::TaskContainerFrontColor, 200))
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
	
	Procedure ChannelSwap_TrackBarHandler()
		Protected *Settings.ChannelSwap_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure ChannelSwap_Populate(*Settings.ChannelSwap_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure ChannelSwap_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
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
	
	Procedure ChannelDisplacement_TrackBarHandler()
		Protected *Settings.ChannelDisplacement_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure ChannelDisplacement_Populate(*Settings.ChannelDisplacement_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
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
	
	Procedure Invertcolor_TrackBarHandler()
		Protected *Settings.Invertcolor_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Invertcolor_Populate(*Settings.Invertcolor_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	Procedure BlackAndWhite_TrackBarHandler()
		Protected *Settings.BlackAndWhite_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure BlackAndWhite_Populate(*Settings.BlackAndWhite_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
		Null.a
	EndStructure
	
	Procedure ColorBalance_TrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_Populate(*Settings.ColorBalance_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure ColorBalance_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_ColorBalance)\Name = "Color Balance"
	Task(#Task_ColorBalance)\Description = "Change the global adjustment of the intensities of the colors."
	Task(#Task_ColorBalance)\Type = MainWindow::#TaskType_Colors
	FillList(ColorBalance)
	;}
	
	;{ Posterization
	Structure Posterization_Settings
		Null.a
	EndStructure
	
	Procedure Posterization_TrackBarHandler()
		Protected *Settings.Posterization_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Posterization_Populate(*Settings.Posterization_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	Procedure Outline_TrackBarHandler()
		Protected *Settings.Outline_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Outline_Populate(*Settings.Outline_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	Procedure TrimImage_TrackBarHandler()
		Protected *Settings.TrimImage_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure TrimImage_Populate(*Settings.TrimImage_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	Procedure Resize_TrackBarHandler()
		Protected *Settings.Resize_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Resize_Populate(*Settings.Resize_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Resize_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
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
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	Procedure Watermark_TrackBarHandler()
		Protected *Settings.Watermark_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Watermark_Populate(*Settings.Watermark_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
		Null.a
	EndStructure
	
	Procedure RotSprite_TrackBarHandler()
		Protected *Settings.RotSprite_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure RotSprite_Populate(*Settings.RotSprite_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure RotSprite_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_Rotsprite)\Name = "Rotsprite"
	Task(#Task_Rotsprite)\Description = "Rotates images using the Rotsprite algorithm by Xenowhirl."
	Task(#Task_Rotsprite)\Type = MainWindow::#TaskType_PixelArt
	FillList(RotSprite)
	;}
	
	;{ Pixel-art upscale
	Structure PixelArtUpscale_Settings
		Null.a
	EndStructure
	
	Procedure PixelArtUpscale_TrackBarHandler()
		Protected *Settings.PixelArtUpscale_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure PixelArtUpscale_Populate(*Settings.PixelArtUpscale_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, "This task output is always the same and doesn't support any setting.")
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure PixelArtUpscale_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Task(#Task_PixelArtUpscale)\Name = "Pixel-art upscale"
	Task(#Task_PixelArtUpscale)\Description = "Upscale sprites using various algorithms."
	Task(#Task_PixelArtUpscale)\Type = MainWindow::#TaskType_PixelArt
	FillList(PixelArtUpscale)
	;}
	
	;{ Save as gif
	Structure SaveGif_Settings
		Null.a
	EndStructure
	
	Procedure SaveGif_TrackBarHandler()
		Protected *Settings.SaveGif_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure SaveGif_Populate(*Settings.SaveGif_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	Procedure Save_TrackBarHandler()
		Protected *Settings.Save_Settings = *CurrentSettings
		Preview::Update()
	EndProcedure
	
	Procedure Save_Populate(*Settings.Save_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, #TextWidth, 15, "No settings")
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
	
	DataSection
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
		
	
	EndDataSection
EndModule
; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 558
; FirstLine = 42
; Folding = ZDAcHc4d4d-d5
; EnableXP