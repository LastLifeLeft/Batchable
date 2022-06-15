Module Tasks
	EnableExplicit
	
	; Private Variale, structure and constants
	Global *CurrentSettings, *CustomCallbackSettings
	Global FontBold = FontID(LoadFont(#PB_Any, "Arial Black", 8, #PB_Font_HighQuality))
	Global NewMap GadgetMap()
	Global NewList ThreadedQueue.Queue(), ThreadID, ThreadInterupt, ThreadCallback, ThreadEndEvent
	
	Enumeration ;Language
		#lng_ColorBalance_Red
		#lng_ColorBalance_Green
		#lng_ColorBalance_Blue
		
		#lng_AlphaThreshold_Value
		
		#__lng_count
	EndEnumeration
	
	Global Dim Language.s(#__lng_count - 1)
	
	
	; private procedures declaration
	Declare ProcessThread(Image)
	
	; Public procedures
	Procedure Process(Image, List TaskQueue.Queue(), EndEvent = #Null)
		Protected *Result, Parameters.s 
		
		If ThreadID ; If a preview was rendering, stop it.
			ThreadInterupt = #True
			WaitThread(ThreadID)
		EndIf
		
		ThreadInterupt = #False
		ThreadEndEvent = EndEvent
		
		CopyList(TaskQueue(), ThreadedQueue())
		ThreadID = CreateThread(@ProcessThread(), CopyImage(Image, #PB_Any))
		
		ProcedureReturn 0
	EndProcedure
	
	; Private procedures
	Procedure ProcessThread(Image)
		ForEach ThreadedQueue()
			If ThreadInterupt
				FreeImage(Image)
				ProcedureReturn #False
			EndIf
			
			Task(ThreadedQueue()\ID)\Execute(Image, ThreadedQueue()\Settings)
		Next
		
		If Not ThreadInterupt And ThreadEndEvent
			PostEvent(ThreadEndEvent, 0, 0, 0, Image)
		Else
			FreeImage(Image)
		EndIf
		
		ThreadID = 0
	EndProcedure
	
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
		Read.s Task(#Task_#TaskName)\Name
		Read.s Task(#Task_#TaskName)\Description
		Task(#Task_#TaskName)\IconID = ImageID(CatchImage(#PB_Any, ?TaskName))
		Task(#Task_#TaskName)\Populate = @TaskName#_Populate()
		Task(#Task_#TaskName)\CleanUp = @TaskName#_CleanUp()
		Task(#Task_#TaskName)\Serialize = @TaskName#_Serialize()
		Task(#Task_#TaskName)\Execute = @TaskName#_Execute()
		Task(#Task_#TaskName)\DefaultSettings = AllocateMemory(SizeOf(TaskName#_Settings))
	EndMacro
	;}
	
	; Tasks
	
	Select General::Language
		Case "français"
			Restore French:
		Default
			Restore English:
	EndSelect
	
	Read.s Language(0); Ignore the first entry
	
	;{ Color Balance
	Structure ColorBalance_Settings
		Red.c
		Green.c
		Blue.c
	EndStructure
	
	Structure ColorBalance_FilterSettings
		Red.d
		Green.d
		Blue.d
	EndStructure
	
	Procedure ColorBalance_RedTrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		*Settings\Red = GetGadgetState(EventGadget()) + 255
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_GreenTrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		*Settings\Green = GetGadgetState(EventGadget()) + 255
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_BlueTrackBarHandler()
		Protected *Settings.ColorBalance_Settings = *CurrentSettings
		*Settings\Blue = GetGadgetState(EventGadget()) + 255
		Preview::Update()
	EndProcedure
	
	Procedure ColorBalance_Populate(*Settings.ColorBalance_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Red Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ColorBalance_Red))
		SetTitleColor(GadgetMap("Red Text"))
		GadgetMap("Red Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 40, -255, 255, UITK::#Trackbar_ShowState)
		AddGadgetItem(GadgetMap("Red Trackbar"), 0, "")
		SetGadgetColor(GadgetMap("Red Trackbar"), UITK::#Color_Special3_Cold, SetAlpha(UITK::WindowGetColor(MainWindow::Window, UITK::#Color_Special1_Cold), 255))
		SetTrackBarColor(GadgetMap("Red Trackbar"))
		SetGadgetState(GadgetMap("Red Trackbar"), *Settings\Red - 255)
		BindGadgetEvent(GadgetMap("Red Trackbar"), @ColorBalance_RedTrackBarHandler(), #PB_EventType_Change)
		
		GadgetMap("Green Text") = TextGadget(#PB_Any, #Margin, #Margin + 75, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ColorBalance_Green))
		SetTitleColor(GadgetMap("Green Text"))
		GadgetMap("Green Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 95, MainWindow::TaskContainerGadgetWidth, 40, -255, 255, UITK::#Trackbar_ShowState)
		AddGadgetItem(GadgetMap("Green Trackbar"), 0, "")
		SetGadgetColor(GadgetMap("Green Trackbar"), UITK::#Color_Special3_Cold, SetAlpha(UITK::WindowGetColor(MainWindow::Window, UITK::#Color_Special2_Cold), 255))
		SetTrackBarColor(GadgetMap("Green Trackbar"))
		SetGadgetState(GadgetMap("Green Trackbar"), *Settings\Green - 255)
		BindGadgetEvent(GadgetMap("Green Trackbar"), @ColorBalance_GreenTrackBarHandler(), #PB_EventType_Change)
		
		GadgetMap("Blue Text") = TextGadget(#PB_Any, #Margin, #Margin + 150, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ColorBalance_Blue))
		SetTitleColor(GadgetMap("Blue Text"))
		GadgetMap("Blue Trackbar") = UITK::TrackBar(#PB_Any,#Margin, #Margin + 170, MainWindow::TaskContainerGadgetWidth, 40, -255, 255, UITK::#Trackbar_ShowState)
		AddGadgetItem(GadgetMap("Blue Trackbar"), 0, "")
		SetTrackBarColor(GadgetMap("Blue Trackbar"))
		SetGadgetState(GadgetMap("Blue Trackbar"), *Settings\Blue - 255)
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
	
	Procedure ColorBalance_Serialize(*Settings.ColorBalance_Settings)
		Protected JSON = CreateJSON(#PB_Any), *Result, ComposedJSON.s
		InsertJSONStructure(JSONValue(JSON), *Settings, ColorBalance_Settings)
		ComposedJSON = ComposeJSON(JSON)
		*Result = AllocateMemory(StringByteLength(ComposedJSON) + 2)
		PokeS(*Result, ComposedJSON)
		FreeJSON(JSON)
		
		ProcedureReturn *Result
	EndProcedure
	
	Procedure ColorBalance_CustomCallback(x, y, SourceColor, TargetColor)
		Protected *FilterSettings.ColorBalance_FilterSettings = *CustomCallbackSettings
		Protected Red.c = Red(SourceColor) * *FilterSettings\Red
		Protected Green.c = Green(SourceColor) * *FilterSettings\Green
		Protected Blue.c = Blue(SourceColor) * *FilterSettings\Blue
		If Red > 255 : Red = 255 : EndIf
		If Green > 255 : Green = 255 : EndIf
		If Blue > 255 : Blue = 255 : EndIf
		
		ProcedureReturn RGBA(Red, Green, Blue,Alpha(SourceColor))
	EndProcedure

	Procedure ColorBalance_Execute(Image, *Settings.ColorBalance_Settings)
		Protected ColorBalance_FilterSettings.ColorBalance_FilterSettings
		ColorBalance_FilterSettings\Red = *Settings\Red / 255 
		ColorBalance_FilterSettings\Green = *Settings\Green / 255
		ColorBalance_FilterSettings\Blue = *Settings\Blue / 255
		*CustomCallbackSettings = @ColorBalance_FilterSettings
		StartDrawing(ImageOutput(Image))
		DrawingMode(#PB_2DDrawing_CustomFilter)
		CustomFilterCallback(@ColorBalance_CustomCallback())
		DrawAlphaImage(ImageID(Image), 0, 0)
		StopDrawing()
		
		ProcedureReturn SizeOf(ColorBalance_Settings)
	EndProcedure
	
	Task(#Task_ColorBalance)\Type = MainWindow::#TaskType_Colors
	FillList(ColorBalance)
	
	Read.s Language(#lng_ColorBalance_Red)
	Read.s Language(#lng_ColorBalance_Green)
	Read.s Language(#lng_ColorBalance_Blue)
	
	PokeC(Task(#Task_ColorBalance)\DefaultSettings, 255)
	PokeC(Task(#Task_ColorBalance)\DefaultSettings + SizeOf(Character), 255)
	PokeC(Task(#Task_ColorBalance)\DefaultSettings + SizeOf(Character) * 2, 255)
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
		
		GadgetMap("Threshold Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_AlphaThreshold_Value))
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
	
	Procedure AlphaThreshold_Serialize(*Settings.AlphaThreshold_Settings)
		
	EndProcedure
	
	Procedure AlphaThreshold_CustomCallback(x, y, SourceColor, TargetColor)
		ProcedureReturn RGBA(Red(SourceColor), Green(SourceColor), Blue(SourceColor), Bool(Alpha(SourceColor) >= *CustomCallbackSettings) * 255)
	EndProcedure
	
	Procedure AlphaThreshold_Execute(Image, *Settings.AlphaThreshold_Settings)
		*CustomCallbackSettings = *Settings\Threshold
		StartDrawing(ImageOutput(Image))
		DrawingMode(#PB_2DDrawing_CustomFilter)
		CustomFilterCallback(@AlphaThreshold_CustomCallback())
		DrawAlphaImage(ImageID(Image), 0, 0)
		StopDrawing()
		
		ProcedureReturn SizeOf(AlphaThreshold_Settings)
	EndProcedure
	
	Task(#Task_AlphaThreshold)\Type = MainWindow::#TaskType_Colors
	FillList(AlphaThreshold)
	Read.s Language(#lng_AlphaThreshold_Value)
	PokeA(Task(#Task_AlphaThreshold)\DefaultSettings, 128)
	;}
	
	DataSection ;{
		English:
		IncludeFile "../Language/Tasks/English.txt"
		
		French:
		IncludeFile "../Language/Tasks/Français.txt"
		
		BlackAndWhite:
		IncludeBinary "../Media/Tinified/Black & White.png"
		
		Blur:
		IncludeBinary "../Media/Tinified/Blur.png"
		
		ChannelDisplacement:
		IncludeBinary "../Media/Tinified/Channel Displacement.png"
		
		ChannelSwap:
		IncludeBinary "../Media/Tinified/Channel swap.png"
		
		ChannelSwap_Red:
		IncludeBinary "../Media/Icon Channel Red.png"
		
		ChannelSwap_Green:
		IncludeBinary "../Media/Icon Channel Green.png"
		
		ChannelSwap_Blue:
		IncludeBinary "../Media/Icon Channel Blue.png"
		
		ChannelSwap_Alpha:
		IncludeBinary "../Media/Icon Channel Alpha.png"
		
		ColorBalance:
		IncludeBinary "../Media/Tinified/Color Balance.png"
		
		Crop:
		IncludeBinary "../Media/Tinified/Crop.png"
		
		SaveGif:
		IncludeBinary "../Media/Tinified/Gif.png"
		
		Invertcolor:
		IncludeBinary "../Media/Tinified/Invert color.png"
		
		Outline:
		IncludeBinary "../Media/Tinified/Outline.png"
		
		PixelArtUpscale:
		IncludeBinary "../Media/Tinified/Pixel Upscale.png"
		
		Posterization:
		IncludeBinary "../Media/Tinified/Posterization.png"
		
		Resize:
		IncludeBinary "../Media/Tinified/Resize.png"
		
		RotSprite:
		IncludeBinary "../Media/Tinified/RotSprite.png"
		
		Save:
		IncludeBinary "../Media/Tinified/Save.png"
		
		AlphaThreshold:
		IncludeBinary "../Media/Tinified/Threshold.png"
		
		TrimImage:
		IncludeBinary "../Media/Tinified/Trim.png"
		
		Watermark:
		IncludeBinary "../Media/Tinified/Watermark.png"
		
	EndDataSection ;}
EndModule

























; IDE Options = PureBasic 6.00 Beta 9 (Windows - x64)
; CursorPosition = 98
; FirstLine = 21
; Folding = pNAAE9
; EnableXP
; DPIAware