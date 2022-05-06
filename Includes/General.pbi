DeclareModule General
	#AppName = "Batchable"
	
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

	Declare Open()
EndDeclareModule

DeclareModule Tasks
	Enumeration ;Tasks
		#Task_AlphaThreshold
		#Task_ChannelSwap
		#Task_ChannelDisplacement
		#Task_InvertColor
		#Task_BlackWhite
		#Task_ColorBalancing
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
		
		#__Task_Count
	EndEnumeration
	
	Prototype Execute(Image, *Settings)
	
	Structure TaskData
		Name.s
		Description.s
		IconID.i
		Type.i
		Execute.Execute
	EndStructure
	
	Global Dim Task.TaskData(#__Task_Count - 1)
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
; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 61
; Folding = O+
; EnableXP