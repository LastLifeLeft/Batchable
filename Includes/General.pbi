DeclareModule General
	Enumeration #PB_Event_FirstCustomValue
		#Update_PreviousTaskDone
		#Update_CurrentTaskDone
		#Update_Preview
		#Update_Resize
		
		#Process_ItemDone
	EndEnumeration
	
	#AppName = "Batchable"
	#SaveVersion = 1
	
	Global ColorMode = UITK::#DarkMode, Portable = #False, Language.s
	Global Settings_MaxThreadCount = CountCPUs(#PB_System_ProcessCPUs) - 1
	; /!\CountCPUs() returns the number of thread, not the number of core. This might help : https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformation
	
	
	
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
	#Window_Height = 501
	#Window_Width = 950
	#ImageList_Width = 400
	#Iconbar_Size = 30
	#Iconbar_Offset = 5
	#ButtonBack_Size = 30
	
	Structure AddListInfo
		ImageID.i
		Description.s
		TaskID.w		;.w is quite optimist there xD
	EndStructure
	
	Structure TaskListInfo Extends AddListInfo
		*TaskSettings
	EndStructure
	
	Global Window
	
	Global TaskContainerWidth, TaskContainerGadgetWidth
	Global TaskContainerBackColor, TaskContainerFrontColor
	
	Global SelectedImagePath.s, SelectedTaskIndex = -1, SetupingTask, TaskList
	
	Declare Open()
EndDeclareModule

DeclareModule Tasks
	Enumeration ;Tasks
		#Task_ColorBalance
		#Task_AlphaThreshold
		#Task_ChannelSwap
		#Task_InvertColor
		#Task_BlackAndWhite
		#Task_Sepia
		
; 		#Task_ChannelDisplacement
; 		#Task_Posterization
; 		#Task_Outline
; 		#Task_TrimImage
; 		#Task_Resize
; 		#Task_Blur
; 		#Task_Watermark
; 		#Task_Rotsprite
; 		#Task_PixelartUpscale
; 		#Task_SaveGif
; 		#Task_Save
; 		#Task_Crop
; 		
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
	
	Structure Queue
		ID.i
		*Settings
	EndStructure
	
	#Margin = 30
	
	Global Dim Task.TaskData(#__Task_Count - 1)
	
	Declare Process(Image, List TaskQueue.Queue(), EndEvent = #Null)
EndDeclareModule

DeclareModule Preview
	Global Window
	
	Declare Open(Forced = #False)
	Declare Update()
	Declare Resize()
EndDeclareModule

DeclareModule Worker
	Global NewList ImageList.s()
	Global NewList TaskQueue.Tasks::Queue()
	
	Declare Init()
	Declare Open()
EndDeclareModule

Module General
	UseJPEG2000ImageDecoder()
	UseJPEGImageDecoder()
	UsePNGImageDecoder()
	UsePNGImageEncoder()
	UseTGAImageDecoder()
	UseTIFFImageDecoder()
	
	Portable = GetLocaleInfo_(#LOCALE_USER_DEFAULT, #LOCALE_SNATIVELANGNAME, @Language, 0)
	Language = Space(Portable)
	GetLocaleInfo_(#LOCALE_USER_DEFAULT, #LOCALE_SNATIVELANGNAME, @Language, Portable)
	
	Portable = #False
	
	Select Language
		Case "français"
			
		Default
 			Language = "english"
	EndSelect
	
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



; IDE Options = PureBasic 6.00 Beta 9 (Windows - x64)
; CursorPosition = 96
; FirstLine = 66
; Folding = -6
; EnableXP
; DPIAware