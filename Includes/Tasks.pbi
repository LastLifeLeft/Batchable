﻿Module Tasks
	EnableExplicit
	
	; Private Variale, structure and constants
	Global *CurrentSettings, *CustomCallbackSettings
	Global FontBold = FontID(LoadFont(#PB_Any, "Arial Black", 8, #PB_Font_HighQuality))
	Global NewMap GadgetMap()
	Global NewList ThreadedQueue.Queue(), ThreadID, ThreadInterupt, ThreadCallback, ThreadEndEvent
	
	Enumeration ;Language
		#lng_NoSetting_Title
		#lng_NoSetting_Description
		
		#lng_ColorBalance_Red
		#lng_ColorBalance_Green
		#lng_ColorBalance_Blue
		
		#lng_AlphaThreshold_Value
		
		#lng_ChannelSwap_Red
		#lng_ChannelSwap_Green
		#lng_ChannelSwap_Blue
		#lng_ChannelSwap_Alpha
		#lng_ChannelSwap_ChannelRed
		#lng_ChannelSwap_ChannelGreen
		#lng_ChannelSwap_ChannelBlue
		#lng_ChannelSwap_ChannelAlpha
		
		
		
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
		
 		If Image
			CopyList(TaskQueue(), ThreadedQueue())
			ThreadID = CreateThread(@ProcessThread(), CopyImage(Image, #PB_Any))
		Else
			PostEvent(ThreadEndEvent, 0, 0, 0, 0)
		EndIf
		
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
		Task(#Task_#TaskName)\Execute = @TaskName#_Execute()
		Task(#Task_#TaskName)\DefaultSettings = AllocateMemory(SizeOf(TaskName#_Settings))
	EndMacro
	;}
	
	; Tasks
	;{ Language
	Select General::Language
		Case "français"
			Restore French:
		Default
			Restore English:
	EndSelect
	
	Read.s Language(0); Ignore the first entry
	Read.s Language(#lng_NoSetting_Title)
	Read.s Language(#lng_NoSetting_Description)
	;}
	
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
	
	;{ Channel Swap
	Structure ChannelSwap_Settings
		Red.a
		Green.a
		Blue.a
		Alpha.a
	EndStructure
	
	Structure ChannelSwap_FilterSettings Extends ChannelSwap_Settings
		Channel.a[4]
	EndStructure
	
	Global ChannelSwap_Icon_Red, ChannelSwap_Icon_Green, ChannelSwap_Icon_Blue, ChannelSwap_Icon_Alpha
	
	ChannelSwap_Icon_Red = ImageID(CatchImage(#PB_Any, ?ChannelSwap_Red))
	ChannelSwap_Icon_Green = ImageID(CatchImage(#PB_Any, ?ChannelSwap_Green))
	ChannelSwap_Icon_Blue = ImageID(CatchImage(#PB_Any, ?ChannelSwap_Blue))
	ChannelSwap_Icon_Alpha = ImageID(CatchImage(#PB_Any, ?ChannelSwap_Alpha))
	
	Procedure ChannelSwap_RedComboHandler()
		Protected *Settings.ChannelSwap_Settings = *CurrentSettings
		*Settings\Red = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ChannelSwap_GreenComboHandler()
		Protected *Settings.ChannelSwap_Settings = *CurrentSettings
		*Settings\Green = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ChannelSwap_BlueComboHandler()
		Protected *Settings.ChannelSwap_Settings = *CurrentSettings
		*Settings\Blue = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ChannelSwap_AlphaComboHandler()
		Protected *Settings.ChannelSwap_Settings = *CurrentSettings
		*Settings\Alpha = GetGadgetState(EventGadget())
		Preview::Update()
	EndProcedure
	
	Procedure ChannelSwap_Populate(*Settings.ChannelSwap_Settings)
		*CurrentSettings = *Settings
		
		GadgetMap("Red Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ChannelSwap_ChannelRed))
		SetTitleColor(GadgetMap("Red Text"))
		GadgetMap("Red Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Red Combo"))
		AddGadgetItem(GadgetMap("Red Combo"), -1, Language(#lng_ChannelSwap_Red), ChannelSwap_Icon_Red)
		AddGadgetItem(GadgetMap("Red Combo"), -1, Language(#lng_ChannelSwap_Green), ChannelSwap_Icon_Green)
		AddGadgetItem(GadgetMap("Red Combo"), -1, Language(#lng_ChannelSwap_Blue), ChannelSwap_Icon_Blue)
		AddGadgetItem(GadgetMap("Red Combo"), -1, Language(#lng_ChannelSwap_Alpha), ChannelSwap_Icon_Alpha)
		BindGadgetEvent(GadgetMap("Red Combo"), @ChannelSwap_RedComboHandler(), #PB_EventType_Change)
		SetGadgetState(GadgetMap("Red Combo"), *Settings\Red)
		
		GadgetMap("Green Text") = TextGadget(#PB_Any, #Margin, #Margin + 65, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ChannelSwap_ChannelGreen))
		SetTitleColor(GadgetMap("Green Text"))
		GadgetMap("Green Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 85, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Green Combo"))
		AddGadgetItem(GadgetMap("Green Combo"), -1, Language(#lng_ChannelSwap_Red), ChannelSwap_Icon_Red)
		AddGadgetItem(GadgetMap("Green Combo"), -1, Language(#lng_ChannelSwap_Green), ChannelSwap_Icon_Green)
		AddGadgetItem(GadgetMap("Green Combo"), -1, Language(#lng_ChannelSwap_Blue), ChannelSwap_Icon_Blue)
		AddGadgetItem(GadgetMap("Green Combo"), -1, Language(#lng_ChannelSwap_Alpha), ChannelSwap_Icon_Alpha)
		BindGadgetEvent(GadgetMap("Green Combo"), @ChannelSwap_GreenComboHandler(), #PB_EventType_Change)
		SetGadgetState(GadgetMap("Green Combo"), *Settings\Green)
		
		GadgetMap("Blue Text") = TextGadget(#PB_Any, #Margin, #Margin + 130, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ChannelSwap_ChannelBlue))
		SetTitleColor(GadgetMap("Blue Text"))
		GadgetMap("Blue Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 150, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Blue Combo"))
		AddGadgetItem(GadgetMap("Blue Combo"), -1, Language(#lng_ChannelSwap_Red), ChannelSwap_Icon_Red)
		AddGadgetItem(GadgetMap("Blue Combo"), -1, Language(#lng_ChannelSwap_Green), ChannelSwap_Icon_Green)
		AddGadgetItem(GadgetMap("Blue Combo"), -1, Language(#lng_ChannelSwap_Blue), ChannelSwap_Icon_Blue)
		AddGadgetItem(GadgetMap("Blue Combo"), -1, Language(#lng_ChannelSwap_Alpha), ChannelSwap_Icon_Alpha)
		BindGadgetEvent(GadgetMap("Blue Combo"), @ChannelSwap_BlueComboHandler(), #PB_EventType_Change)
		SetGadgetState(GadgetMap("Blue Combo"), *Settings\Blue)
		
		GadgetMap("Alpha Text") = TextGadget(#PB_Any, #Margin, #Margin + 195, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_ChannelSwap_ChannelAlpha))
		SetTitleColor(GadgetMap("Alpha Text"))
		GadgetMap("Alpha Combo") = UITK::Combo(#PB_Any, #Margin, #Margin + 215, MainWindow::TaskContainerGadgetWidth, 30)
		SetComboColor(GadgetMap("Alpha Combo"))
		AddGadgetItem(GadgetMap("Alpha Combo"), -1, Language(#lng_ChannelSwap_Red), ChannelSwap_Icon_Red)
		AddGadgetItem(GadgetMap("Alpha Combo"), -1, Language(#lng_ChannelSwap_Green), ChannelSwap_Icon_Green)
		AddGadgetItem(GadgetMap("Alpha Combo"), -1, Language(#lng_ChannelSwap_Blue), ChannelSwap_Icon_Blue)
		AddGadgetItem(GadgetMap("Alpha Combo"), -1, Language(#lng_ChannelSwap_Alpha), ChannelSwap_Icon_Alpha)
		BindGadgetEvent(GadgetMap("Alpha Combo"), @ChannelSwap_AlphaComboHandler(), #PB_EventType_Change)
		SetGadgetState(GadgetMap("Alpha Combo"), *Settings\Alpha)
		
	EndProcedure
	
	Procedure ChannelSwap_CleanUp()
		FreeGadget(GadgetMap("Red Text"))
		BindGadgetEvent(GadgetMap("Red Combo"), @ChannelSwap_RedComboHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Red Combo"))
		
		FreeGadget(GadgetMap("Green Text"))
		BindGadgetEvent(GadgetMap("Green Combo"), @ChannelSwap_GreenComboHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Green Combo"))
		
		FreeGadget(GadgetMap("Blue Text"))
		BindGadgetEvent(GadgetMap("Blue Combo"), @ChannelSwap_BlueComboHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Blue Combo"))
		
		FreeGadget(GadgetMap("Alpha Text"))
		BindGadgetEvent(GadgetMap("Alpha Combo"), @ChannelSwap_AlphaComboHandler(), #PB_EventType_Change)
		FreeGadget(GadgetMap("Alpha Combo"))
		
		ClearMap(GadgetMap())
	EndProcedure
	
	Procedure ChannelSwap_CustomCallback(x, y, SourceColor, TargetColor)
		Protected *Settings.ChannelSwap_FilterSettings = *CustomCallbackSettings
		*Settings\Channel[0] = Red(SourceColor)
		*Settings\Channel[1] = Green(SourceColor)
		*Settings\Channel[2] = Blue(SourceColor)
		*Settings\Channel[3] = Alpha(SourceColor)
		
		ProcedureReturn RGBA(*Settings\Channel[*Settings\Red], *Settings\Channel[*Settings\Green], *Settings\Channel[*Settings\Blue], *Settings\Channel[*Settings\Alpha])
	EndProcedure
	
	Procedure ChannelSwap_Execute(Image, *Settings.ChannelSwap_Settings)
		Protected FilterSettings.ChannelSwap_FilterSettings
		FilterSettings\Red = *Settings\Red
		FilterSettings\Green = *Settings\Green
		FilterSettings\Blue = *Settings\Blue
		FilterSettings\Alpha = *Settings\Alpha
		*CustomCallbackSettings = @FilterSettings
		StartDrawing(ImageOutput(Image))
		DrawingMode(#PB_2DDrawing_CustomFilter)
		CustomFilterCallback(@ChannelSwap_CustomCallback())
		DrawAlphaImage(ImageID(Image), 0, 0)
		StopDrawing()
		ProcedureReturn SizeOf(ChannelSwap_Settings)
	EndProcedure
	
	Task(#Task_ChannelSwap)\Type = MainWindow::#TaskType_Colors
	FillList(ChannelSwap)
	
	Read.s Language(#lng_ChannelSwap_Red)
	Read.s Language(#lng_ChannelSwap_Green)
	Read.s Language(#lng_ChannelSwap_Blue)
	Read.s Language(#lng_ChannelSwap_Alpha)
	Read.s Language(#lng_ChannelSwap_ChannelRed)
	Read.s Language(#lng_ChannelSwap_ChannelGreen)
	Read.s Language(#lng_ChannelSwap_ChannelBlue)
	Read.s Language(#lng_ChannelSwap_ChannelAlpha)
	
	PokeA(Task(#Task_ChannelSwap)\DefaultSettings, 0)
	PokeA(Task(#Task_ChannelSwap)\DefaultSettings + OffsetOf(ChannelSwap_Settings\Green), 1)
	PokeA(Task(#Task_ChannelSwap)\DefaultSettings + OffsetOf(ChannelSwap_Settings\Blue), 2)
	PokeA(Task(#Task_ChannelSwap)\DefaultSettings + OffsetOf(ChannelSwap_Settings\Alpha), 3)
	;}
	
	;{ Invert Color
	Structure Invertcolor_Settings
		Null.a
	EndStructure
	
	Procedure Invertcolor_Populate(*Settings.Invertcolor_Settings)
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_NoSetting_Title))
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, Language(#lng_NoSetting_Description))
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Invertcolor_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Procedure Invertcolor_CustomCallback(x, y, SourceColor, TargetColor)
		ProcedureReturn RGBA(255 - Red(SourceColor), 255 - Green(SourceColor), 255 - Blue(SourceColor), Alpha(SourceColor))
	EndProcedure
	
	Procedure Invertcolor_Execute(Image, *Settings)
		StartDrawing(ImageOutput(Image))
		DrawingMode(#PB_2DDrawing_CustomFilter)
		CustomFilterCallback(@Invertcolor_CustomCallback())
		DrawAlphaImage(ImageID(Image), 0, 0)
		StopDrawing()
		ProcedureReturn SizeOf(Invertcolor_Settings)
	EndProcedure
	
	Task(#Task_InvertColor)\Type = MainWindow::#TaskType_Colors
	FillList(Invertcolor)
	;}
	
	;{ Black & White
	Structure BlackAndWhite_Settings
		Null.a
	EndStructure
	
	Procedure BlackAndWhite_Populate(*Settings.BlackAndWhite_Settings)
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_NoSetting_Title))
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, Language(#lng_NoSetting_Description))
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure BlackAndWhite_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Procedure BlackAndWhite_CustomCallback(x, y, SourceColor, TargetColor)
		Protected Color.a = Round((Red(SourceColor) * 0.2989 + Green(SourceColor) * 0.5870 + Blue(SourceColor) * 0.1140), #PB_Round_Down)
		ProcedureReturn RGBA(Color, Color, Color, Alpha(SourceColor))
	EndProcedure
	
	Procedure BlackAndWhite_Execute(Image, *Settings)
		StartDrawing(ImageOutput(Image))
		DrawingMode(#PB_2DDrawing_CustomFilter)
		CustomFilterCallback(@BlackAndWhite_CustomCallback())
		DrawAlphaImage(ImageID(Image), 0, 0)
		StopDrawing()
		ProcedureReturn SizeOf(BlackAndWhite_Settings)
	EndProcedure
	
	Task(#Task_BlackAndWhite)\Type = MainWindow::#TaskType_Colors
	FillList(BlackAndWhite)
	;}
	
	;{ Sepia
	Structure Sepia_Settings
		Null.a
	EndStructure
	
	Procedure Sepia_Populate(*Settings.Sepia_Settings)
		GadgetMap("Title Text") = TextGadget(#PB_Any, #Margin, #Margin, MainWindow::TaskContainerGadgetWidth, 15, Language(#lng_NoSetting_Title))
		SetTitleColor(GadgetMap("Title Text"))
		GadgetMap("Description Text") = TextGadget(#PB_Any, #Margin, #Margin + 20, MainWindow::TaskContainerWidth - #Margin * 2, 45, Language(#lng_NoSetting_Description))
		SetTextColor(GadgetMap("Description Text"))
	EndProcedure
	
	Procedure Sepia_CleanUp()
		FreeGadget(GadgetMap("Title Text"))
		FreeGadget(GadgetMap("Description Text"))
		ClearMap(GadgetMap())
	EndProcedure
	
	Procedure Sepia_CustomCallback(x, y, SourceColor, TargetColor)
		
		ProcedureReturn RGBA(General::Min((Red(SourceColor) * 0.393 + Green(SourceColor) * 0.769 + Blue(SourceColor) * 0.189), 255),
		                     General::Min((Red(SourceColor) * 0.349 + Green(SourceColor) * 0.686 + Blue(SourceColor) * 0.168), 255), 
		                     General::Min((Red(SourceColor) * 0.272 + Green(SourceColor) * 0.534 + Blue(SourceColor) * 0.131), 255), Alpha(SourceColor))
	EndProcedure
	
	Procedure Sepia_Execute(Image, *Settings)
		StartDrawing(ImageOutput(Image))
		DrawingMode(#PB_2DDrawing_CustomFilter)
		CustomFilterCallback(@Sepia_CustomCallback())
		DrawAlphaImage(ImageID(Image), 0, 0)
		StopDrawing()
		ProcedureReturn SizeOf(Sepia_Settings)
	EndProcedure
	
	Task(#Task_Sepia)\Type = MainWindow::#TaskType_Colors
	FillList(Sepia)
	;}
	
	DataSection ;{
		English:
		IncludeFile "../Language/Tasks/English.pb"
		
		French:
		IncludeFile "../Language/Tasks/Français.pb"
		
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
		
		Sepia:
		IncludeBinary "../Media/Tinified/Sepia.png"
		
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
; CursorPosition = 556
; FirstLine = 66
; Folding = pNUAAAAAA+
; EnableXP
; DPIAware