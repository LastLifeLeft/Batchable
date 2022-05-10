DeclareModule General
	#AppName = "Batchable"
	
	Global ColorMode = UITK::#DarkMode
	
	; Public procedure declarations
	Declare Min(A, B)
	Declare Max(A, B)
EndDeclareModule

DeclareModule MainWindow
	Enumeration ;Task type
		#TaskType_All
		#TaskType_Colors
		#TaskType_Transformation
		#TaskType_PixelArt
		#TaskType_Other
	EndEnumeration
	
	#MenuBar_Height = 0
	#Window_Margin = 12
	#Window_Height = 500
	#Window_Width = 950
	#ImageList_Width = 400
	#Iconbar_Size = 30
	#Iconbar_Offset = 5
	#ButtonBack_Size = 30
	
	Global Window
	
	Global TaskContainerWidth, TaskContainerGadgetWidth
	Global TaskContainerBackColor, TaskContainerFrontColor
	
	Declare Open()
EndDeclareModule

DeclareModule Tasks
	Enumeration ;Tasks
		#Task_AlphaThreshold
		#Task_ChannelSwap
		#Task_ChannelDisplacement
		#Task_InvertColor
		#Task_BlackAndWhite
		#Task_ColorBalance
		#Task_Posterization
		#Task_Outline
		#Task_TrimImage
		#Task_Resize
		#Task_Blur
		#Task_Watermark
		#Task_Rotsprite
		#Task_PixelartUpscale
		#Task_SaveGif
		#Task_Save
		#Task_Crop
		
		#__Task_Count
	EndEnumeration
	
	Prototype Execute(Image, *Settings)
	Prototype Populate(*Settings)
	Prototype CleanUp()
	
	Structure TaskData
		Name.s
		Description.s
		IconID.i
		Type.i
		Execute.Execute
		Populate.Populate
		CleanUp.CleanUp
		*DefaultSettings
	EndStructure
	
	#Margin = 30
	
	Global Dim Task.TaskData(#__Task_Count - 1)
EndDeclareModule

DeclareModule Preview
	Global Window
	
	Declare Open()
	Declare Update()
EndDeclareModule

Module General
	UseJPEG2000ImageDecoder()
	UseJPEGImageDecoder()
	UsePNGImageDecoder()
	UseTGAImageDecoder()
	UseTIFFImageDecoder()
	
	;{ Public procedures
	Procedure Min(A, B)
		If A > B
			ProcedureReturn B
		EndIf
		ProcedureReturn A
	EndProcedure
	
	Procedure Max(A, B)
		If A < B
			ProcedureReturn B
		EndIf
		ProcedureReturn A
	EndProcedure
	;}
	
EndModule

; IDE Options = PureBasic 6.00 Beta 7 (Windows - x64)
; CursorPosition = 18
; Folding = f9
; EnableXP