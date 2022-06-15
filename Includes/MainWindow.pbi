Module MainWindow
	EnableExplicit
	RegisterFontFile("UITK Icon Font.ttf")
	Global IconFont = FontID(LoadFont(#PB_Any, "UITK Icon Font", 18, #PB_Font_HighQuality))
	
	; Macro
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
	
	Macro SetButtonColor(Button, Parent, BackCold, Back_Warm, BackHot, TextWarm, TextHot, ToolTip, Text)
		TempImage = CreateImage(#PB_Any, 26, 24, 32, #PB_Image_Transparent)
		StartDrawing(ImageOutput(TempImage))
		DrawingFont(IconFont)
		DrawingMode(#PB_2DDrawing_AllChannels)
		DrawText(2, 0, " "+text+" ", SetAlpha(FixColor($FAFAFB), 255), 0)
		StopDrawing()
		UITK::SetGadgetImage(Button, ImageID(TempImage))
		
		SetGadgetAttribute(Button, #PB_Canvas_Cursor, #PB_Cursor_Hand)
		SetGadgetColor(Button, UITK::#Color_Parent, SetAlpha(Parent, 255))
		SetGadgetColor(Button, UITK::#Color_Back_Cold, SetAlpha(BackCold, 255))
		SetGadgetColor(Button, UITK::#Color_Back_Disabled, SetAlpha(BackCold, 255))
		SetGadgetColor(Button, UITK::#Color_Back_Warm, SetAlpha(FixColor(Back_Warm), 255))
		SetGadgetColor(Button, UITK::#Color_Back_Hot, SetAlpha(FixColor(BackHot), 255))
		SetGadgetColor(Button, UITK::#Color_Text_Warm, SetAlpha(FixColor(TextWarm), 255))
		SetGadgetColor(Button, UITK::#Color_Text_Hot, SetAlpha(FixColor(TextHot), 255))
		GadgetToolTip(Button, ToolTip)
	EndMacro
	
	;{ Private variables, structures and constants
	Structure PreviewLoading
		*Data
		File.s
	EndStructure
	
	Structure OriginalImageInfo
		ImageID.i
		Image.i
		Path.s
		Information.s
		File.s
	EndStructure
		
	Structure AddListItem
		Text.UITK::Text
		*Data.AddListInfo
	EndStructure
	
	Structure TaskListItem
		Text.UITK::Text
		*Data.TaskListInfo
	EndStructure
	
	Structure ImageListItem
		Text.UITK::Text
		*Data.OriginalImageInfo
	EndStructure
	
	Enumeration ;Language
		#lng_AddImages
		#lng_AddFolder
		#lng_RemoveImage
		
		#lng_AddTask
		#lng_TaskSettings
		#lng_RemoveTask
		#lng_Process
		
		#lng_TaskType_All
		#lng_TaskType_Colors
		#lng_TaskType_Transformation
		#lng_TaskType_PixelArt
		#lng_TaskType_Other
		
		#lng_Menu_Files
		#lng_Menu_Preferences
		#lng_Menu_Exit
		
		#lng_Menu_Tasks
		#lng_Menu_LoadTasksList
		#lng_Menu_SaveTasksList
		#lng_Menu_DisplayPreview
		
		#lng_Menu_Help
		#lng_Menu_About
		#lng_Menu_Guide
		#lng_Menu_Website
		
		#lng_Cancel
		#lng_AddtoQueue
		#lng_Back
		
		#lng_Error_Loading
		
		#__lng_size
	EndEnumeration
	
	Global ImageList, ImageContainer, ButtonAddImage, ButtonAddFolder, ButtonRemoveImage, TaskContainer, ButtonAddTask, ButtonSetupTask, ButtonRemoveTask, ButtonProcess, NewTaskContainer, NewTaskReturnButton, NewTaskCombo, NewTaskList, NewTaskButton
	Global TaskSettingContainer, TaskSettingReturnButton, NewList TaskSettingList()
	Global BoldFont = FontID(LoadFont(#PB_Any, "Segoe UI", 9, #PB_Font_HighQuality | #PB_Font_Bold))
	Global ImageLoading, ImageError, ImageLoadingID
	Global PreviewMutex, MiniatureThreat, NewList PreviewList.PreviewLoading()
	Global Menu, PreviewCheckerboard
	Global Dim Language.s(#__lng_size - 1)
	
	#SupportedFileTypes = "jpgjpegpngbmptifftga"
	
	PreviewMutex = CreateMutex()
	
	ImageLoading = CreateImage(#PB_Any, 94, 70, 24, FixColor($202225))
	StartVectorDrawing(ImageVectorOutput(ImageLoading))
	VectorSourceColor(SetAlpha(FixColor($C0C0C0), 255))
	AddPathCircle(47, 35, 22)
	FillPath()
	VectorSourceColor(SetAlpha(FixColor($202225), 255))
	MovePathCursor(47, 21)
	AddPathLine(0, 15, #PB_Path_Relative)
	StrokePath(3)
	MovePathCursor(47, 35)
	AddPathLine(10, -10, #PB_Path_Relative)
	StrokePath(3)
	StopVectorDrawing()
	ImageLoadingID = ImageID(ImageLoading)
	
	ImageError = CreateImage(#PB_Any, 94, 70, 24, FixColor($202225))
	StartVectorDrawing(ImageVectorOutput(ImageError))
	VectorSourceColor(SetAlpha(FixColor($D83C3E), 255))
	MovePathCursor(32, 20)
	AddPathLine(30, 30, #PB_Path_Relative)
	MovePathCursor(0, -30, #PB_Path_Relative)
	AddPathLine(-30, 30, #PB_Path_Relative)
	StrokePath(4)
	StopVectorDrawing()
	
	Enumeration ;Menu
		#Menu_OpenImages
		#Menu_OpenFolder
		#Menu_Settings
		#Menu_Quit
		#Menu_LoadTasks
		#Menu_SaveTasks
		#Menu_ShowPreview
		#Menu_About
		#Menu_Help
		#Menu_VisitSite
	EndEnumeration
	
	#ToolBarHeight = 40
	;}
	
	;{ Private procedures declaration
	Declare ImageList_ItemRedraw(*Item.ImageListItem, X, Y, Width, Height, State)
	Declare TaskList_ItemRedraw(*Item.AddListItem, X, Y, Width, Height, State)
	
	Declare Handler_Drop()
	Declare Handler_ImageList()
	Declare Handler_ImageList_Forceful()
	Declare Handler_ImageList_Keyboard()
	Declare Handler_AddImage()
	Declare Handler_AddFolder()
	Declare Handler_RemoveImage()
	
	Declare Handler_TaskList()
	Declare Handler_TaskList_Keyboard()
	Declare Handler_NewTask()
	Declare Handler_SetupTask()
	Declare Handler_RemoveTask()
	
	Declare Handler_NewTaskButton()
	Declare Handler_NewTaskCombo()
	Declare Handler_NewTaskList()
	Declare Handler_NewTaskReturn()
	
	Declare Handler_Menu_Preview()
	
	Declare Handler_TaskSettingReturn()
	
	Declare Handler_Close()
	
	Declare Thread_LoadMiniature(Null)
	
	Declare Populate_TaskList(Type)
	Declare AddImageToQueue(File.s)
	Declare NewTaskToQueue(Task)
	Declare.s BrowseFolder(Folder.s)
	
	;}
	
	; Public procedures
	Procedure Open()
		Protected Loop, TempImage
		
		PreviewCheckerboard = CreateImage(#PB_Any, 128, 128, 24, FixColor($FFFFFF))
		StartVectorDrawing(ImageVectorOutput(PreviewCheckerboard))
		For Loop = 0 To 128 Step 16
			AddPathBox(Loop, 0, 8, 128)
			AddPathBox(0, Loop, 128, 8)
		Next
		VectorSourceColor(SetAlpha($BFBFBF, 255))
		FillPath()
		StopVectorDrawing()
		
		Select General::Language
			Case "français"
				Restore French:
			Default
				Restore English:
		EndSelect
		
		Read.s Language(0); Ignore the first entry
		
		For Loop = #lng_AddImages To #__lng_size - 1
			Read.s Language(Loop)
		Next
		
		Window = UITK::Window(#PB_Any, 0, 0, #Window_Width, #Window_Height, General::#AppName, General::ColorMode | UITK::#Window_CloseButton | #PB_Window_ScreenCentered | #PB_Window_Invisible)
		BindEvent(#PB_Event_CloseWindow, @Handler_Close(), Window)
		UITK::SetWindowIcon(Window, ImageID(CatchImage(#PB_Any, ?Icon)))
		BindEvent(#PB_Event_GadgetDrop, @Handler_Drop())
		
		ImageContainer = UITK::Container(#PB_Any, #Window_Margin, #MenuBar_Height + #Window_Margin, #ImageList_Width, #Window_Height - #MenuBar_Height - #Window_Margin * 2)
		SetGadgetAttribute(ImageContainer, UITK::#Attribute_CornerRadius, 5)
		ImageList = UITK::VerticalList(#PB_Any, 0, #ToolBarHeight, #ImageList_Width, #Window_Height - #MenuBar_Height - #Window_Margin * 2 - #ToolBarHeight, UITK::#ReOrder, @ImageList_ItemRedraw())
		SetGadgetAttribute(ImageList, UITK::#Attribute_CornerType, UITK::#Corner_Bottom)
		SetGadgetAttribute(ImageList, UITK::#Attribute_CornerRadius, 5)
		SetGadgetAttribute(ImageList, UITK::#Attribute_ItemHeight, 90)
		EnableGadgetDrop(ImageList, #PB_Drop_Files, #PB_Drag_Move)
		BindGadgetEvent(ImageList, @Handler_ImageList(), #PB_EventType_Change)
		BindGadgetEvent(ImageList, @Handler_ImageList_Forceful(), UITK::#Eventtype_ForcefulChange)
		BindGadgetEvent(ImageList, @Handler_ImageList_Keyboard(), #PB_EventType_KeyDown)
		
		ButtonAddImage = UITK::Button(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonAddImage, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, Language(#lng_AddImages), "a")
		BindGadgetEvent(ButtonAddImage, @Handler_AddImage(), #PB_EventType_Change)
		
		ButtonAddFolder = UITK::Button(#PB_Any, #Iconbar_Offset * 2 + #Iconbar_Size, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonAddFolder, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, Language(#lng_AddFolder), "c")
		BindGadgetEvent(ButtonAddFolder, @Handler_AddFolder(), #PB_EventType_Change)
		
		ButtonRemoveImage = UITK::Button(#PB_Any, #Iconbar_Offset * 3 + #Iconbar_Size * 2, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonRemoveImage, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $D83C3E, $E06365, $FAFAFB, $FAFAFB, Language(#lng_RemoveImage), "b")
		BindGadgetEvent(ButtonRemoveImage, @Handler_RemoveImage(), #PB_EventType_Change)
		UITK::Disable(ButtonRemoveImage, #True)
		CloseGadgetList()
		
		TaskContainer = UITK::Container(#PB_Any, #Window_Margin * 2 + #ImageList_Width, #MenuBar_Height + #Window_Margin, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2)
		SetGadgetAttribute(TaskContainer, UITK::#Attribute_CornerRadius, 5)
		TaskList = UITK::VerticalList(#PB_Any, 0, #ToolBarHeight, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2 - #ToolBarHeight, UITK::#ReOrder, @TaskList_ItemRedraw())
		SetGadgetAttribute(TaskList, UITK::#Attribute_CornerType, UITK::#Corner_Bottom)
		SetGadgetAttribute(TaskList, UITK::#Attribute_ItemHeight, 60)
		SetGadgetAttribute(TaskList, UITK::#Attribute_CornerRadius, 5)
		BindGadgetEvent(TaskList, @Handler_TaskList(), #PB_EventType_Change)
		BindGadgetEvent(TaskList, @Handler_SetupTask(), UITK::#Eventtype_ForcefulChange)
		BindGadgetEvent(TaskList, @Handler_TaskList_Keyboard(), #PB_EventType_KeyDown)
		
		ButtonAddTask = UITK::Button(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonAddTask, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, Language(#lng_AddTask), "e")
		BindGadgetEvent(ButtonAddTask, @Handler_NewTask(), #PB_EventType_Change)
		
		ButtonSetupTask = UITK::Button(#PB_Any, #Iconbar_Offset * 2 + #Iconbar_Size, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonSetupTask, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, Language(#lng_TaskSettings), "g")
		UITK::Disable(ButtonSetupTask, #True)
		BindGadgetEvent(ButtonSetupTask, @Handler_SetupTask(), #PB_EventType_Change)
		
		ButtonRemoveTask = UITK::Button(#PB_Any, #Iconbar_Offset * 3 + #Iconbar_Size * 2, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonRemoveTask, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $D83C3E, $E06365, $FAFAFB, $FAFAFB, Language(#lng_RemoveTask), "f")
		UITK::Disable(ButtonRemoveTask, #True)
		BindGadgetEvent(ButtonRemoveTask, @Handler_RemoveTask(), #PB_EventType_Change)
		
		ButtonProcess = UITK::Button(#PB_Any, #Iconbar_Offset * 4 + #Iconbar_Size * 3, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "")
		SetButtonColor(ButtonProcess, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $3AA55D, $6BD08B, $FAFAFB, $FAFAFB, Language(#lng_Process), "h")
		UITK::Disable(ButtonProcess, #True)
		CloseGadgetList()
		
		NewTaskContainer = UITK::Container(#PB_Any, #Window_Margin * 2 + #ImageList_Width, #MenuBar_Height + #Window_Margin, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2)
		SetGadgetAttribute(NewTaskContainer, UITK::#Attribute_CornerRadius, 5)
		HideGadget(NewTaskContainer, #True)
		
		TaskContainerWidth = GadgetWidth(NewTaskContainer)
		TaskContainerBackColor = GetGadgetColor(NewTaskContainer, UITK::#Color_Shade_Cold)
		TaskContainerFrontColor = GetGadgetColor(NewTaskContainer, UITK::#Color_Text_Cold)
		TaskContainerGadgetWidth = TaskContainerWidth - Tasks::#Margin * 2
		
		NewTaskCombo = UITK::Combo(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, 200, #ButtonBack_Size, UITK::#Border)
		
		SetGadgetColor(NewTaskCombo, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskCombo, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(NewTaskCombo, UITK::#Color_Back_Cold), 255))
		
		AddGadgetItem(NewTaskCombo, #TaskType_All, Language(#lng_TaskType_All))
		AddGadgetItem(NewTaskCombo, #TaskType_Colors, Language(#lng_TaskType_Colors))
		AddGadgetItem(NewTaskCombo, #TaskType_Transformation, Language(#lng_TaskType_Transformation))
		AddGadgetItem(NewTaskCombo, #TaskType_PixelArt, Language(#lng_TaskType_PixelArt))
		AddGadgetItem(NewTaskCombo, #TaskType_Other, Language(#lng_TaskType_Other))
		SetGadgetState(NewTaskCombo, 0)
		BindGadgetEvent(NewTaskCombo, @Handler_NewTaskCombo(), #PB_EventType_Change)
		
		NewTaskList = UITK::VerticalList(#PB_Any, 0, #Iconbar_Offset * 2 + #ButtonBack_Size, TaskContainerWidth, GadgetHeight(NewTaskContainer) - #Iconbar_Offset * 4 - #ButtonBack_Size * 2, UITK::#Default, @TaskList_ItemRedraw())
		SetGadgetAttribute(NewTaskList, UITK::#Attribute_CornerRadius, 0)
		BindGadgetEvent(NewTaskList, @Handler_NewTaskList(), #PB_EventType_Change)
		BindGadgetEvent(NewTaskList, @Handler_NewTaskButton(), UITK::#Eventtype_ForcefulChange)
		SetGadgetAttribute(NewTaskList, UITK::#Attribute_ItemHeight, 60)
		SetGadgetAttribute(NewTaskList, UITK::#Attribute_SortItems, #True)
		Populate_TaskList(0)
		
		NewTaskReturnButton = UITK::Button(#PB_Any, TaskContainerWidth - 150 - #Iconbar_Offset, GadgetHeight(NewTaskContainer) - #Iconbar_Offset - #ButtonBack_Size, 150, #ButtonBack_Size, Language(#lng_Cancel), UITK::#Border)
		BindGadgetEvent(NewTaskReturnButton, @Handler_NewTaskReturn(), #PB_EventType_Change)
		SetGadgetAttribute(NewTaskReturnButton, #PB_Canvas_Cursor, #PB_Cursor_Hand)
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Back_Cold, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Warm), 255))
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Back_Hot, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Hot), 255))
		
		NewTaskButton = UITK::Button(#PB_Any, TaskContainerWidth - 300 - #Iconbar_Offset * 2, GadgetHeight(NewTaskContainer) - #Iconbar_Offset - #ButtonBack_Size, 150, #ButtonBack_Size, Language(#lng_AddtoQueue), UITK::#Border)
		SetGadgetColor(NewTaskButton, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskButton, UITK::#Color_Back_Cold, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskButton, UITK::#Color_Back_Disabled, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskButton, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Warm), 255))
		SetGadgetColor(NewTaskButton, UITK::#Color_Back_Hot, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Hot), 255))
		BindGadgetEvent(NewTaskButton, @Handler_NewTaskButton(), #PB_EventType_Change)
		
		UITK::Disable(NewTaskButton, #True)
		
		CloseGadgetList()
		
		TaskSettingContainer = UITK::Container(#PB_Any, #Window_Margin * 2 + #ImageList_Width, #MenuBar_Height + #Window_Margin, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2)
		SetGadgetAttribute(TaskSettingContainer, UITK::#Attribute_CornerRadius, 5)
		HideGadget(TaskSettingContainer, #True)
		
		TaskSettingReturnButton =  UITK::Button(#PB_Any, TaskContainerWidth - 100 - #Iconbar_Offset, GadgetHeight(NewTaskContainer) - #Iconbar_Offset - #ButtonBack_Size, 100, #ButtonBack_Size, Language(#lng_Back), UITK::#Border)
 		BindGadgetEvent(TaskSettingReturnButton, @Handler_TaskSettingReturn(), #PB_EventType_Change)
		SetGadgetAttribute(TaskSettingReturnButton, #PB_Canvas_Cursor, #PB_Cursor_Hand)
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Back_Cold, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Warm), 255))
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Back_Hot, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Hot), 255))
		
		CloseGadgetList()
		
		Menu = UITK::FlatMenu(General::ColorMode)
		UITK::AddFlatMenuItem(Menu, #Menu_OpenImages, -1, Language(#lng_AddImages))
		UITK::AddFlatMenuItem(Menu, #Menu_OpenFolder, -1, Language(#lng_AddFolder))
		UITK::AddFlatMenuSeparator(Menu, -1)
		UITK::AddFlatMenuItem(Menu, #Menu_Settings, -1, Language(#lng_Menu_Preferences))
		UITK::AddFlatMenuSeparator(Menu, -1)
		UITK::AddFlatMenuItem(Menu, #Menu_Quit, -1, Language(#lng_Menu_Exit))
		UITK::AddWindowMenu(Window, Menu, Language(#lng_Menu_Files))
		
		Menu = UITK::FlatMenu(General::ColorMode)
		UITK::AddFlatMenuItem(Menu, #Menu_LoadTasks, -1, Language(#lng_Menu_LoadTasksList))
		UITK::AddFlatMenuItem(Menu, #Menu_SaveTasks, -1, Language(#lng_Menu_SaveTasksList))
		UITK::AddFlatMenuSeparator(Menu, -1)
		UITK::AddFlatMenuItem(Menu, #Menu_ShowPreview, -1, Language(#lng_Menu_DisplayPreview))
		UITK::AddWindowMenu(Window, Menu, Language(#lng_Menu_Tasks))
		
		Menu = UITK::FlatMenu(General::ColorMode)
		UITK::AddFlatMenuItem(Menu, #Menu_About, -1,  Language(#lng_Menu_About))
		UITK::AddFlatMenuItem(Menu, #Menu_Help, -1, Language(#lng_Menu_Guide))
		UITK::AddFlatMenuItem(Menu, #Menu_VisitSite, -1, Language(#lng_Menu_Website))
		UITK::AddWindowMenu(Window, Menu, Language(#lng_Menu_Help))
		
		CreatePopupMenu(0) ;< ╯︿╰ can't bind menu event without that ...
		
		BindMenuEvent(0, #Menu_OpenImages, @Handler_AddImage())
		BindMenuEvent(0, #Menu_OpenFolder, @Handler_AddFolder())
		BindMenuEvent(0, #Menu_Quit, @Handler_Close())
		
		BindMenuEvent(0, #Menu_ShowPreview, @Handler_Menu_Preview())
		
		HideWindow(Window, #False)
		
	EndProcedure
	
	;{ Private procedures
	Procedure ImageList_ItemRedraw(*Item.ImageListItem, X, Y, Width, Height, State)
		Protected *OriginalImageInfo.OriginalImageInfo, NameWidth, PathWidth, InformationWidth
		
		If *Item\Data
			VectorFont(BoldFont)
			
			MovePathCursor(X + 10, Y + 10)
			DrawVectorImage(*Item\Data\ImageID)
			
			MovePathCursor(X + 113, Y + 15)
			DrawVectorParagraph("Name:", 200, 20)
			NameWidth = VectorTextWidth("Name:")
			
			MovePathCursor(X + 113, Y + 36)
			DrawVectorParagraph("Path:", 200, 20)
			PathWidth = VectorTextWidth("Path:")
			
			MovePathCursor(X + 113, Y + 57)
			DrawVectorParagraph("Attributes:", 200, 20)
			InformationWidth = VectorTextWidth("Attributes:")
			
			VectorFont(*Item\Text\FontID)
			MovePathCursor(X + 118 + NameWidth, Y + 15)
			DrawVectorParagraph(*Item\Text\Text, 200, 20)
			
			MovePathCursor(X + 118 + PathWidth, Y + 36)
			DrawVectorParagraph(*Item\Data\Path, #ImageList_Width - PathWidth - 130, 20)
			
			MovePathCursor(X + 118 + InformationWidth, Y + 57)
			DrawVectorParagraph(*Item\Data\Information, #ImageList_Width - InformationWidth - 130, 20)
		EndIf
	EndProcedure
	
	Procedure TaskList_ItemRedraw(*Item.AddListItem, X, Y, Width, Height, State)
		VectorFont(BoldFont)
		UITK::DrawVectorTextBlock(@*Item\Text, X + 70, Y - 18)
		
		If *Item\Data
			VectorFont(*Item\Text\FontID)
			MovePathCursor(X + 70, Y + 22)
			DrawVectorParagraph(*Item\Data\Description, Width - 80, 40)
			MovePathCursor(X + 10, Y + 5)
			DrawVectorImage(*Item\Data\ImageID)
		EndIf
		
	EndProcedure
	
	Procedure Handler_Drop()
		AddImageToQueue(EventDropFiles())
	EndProcedure
	
	Procedure Handler_ImageList()
		Protected *Data.OriginalImageInfo, State = GetGadgetState(ImageList)
		
		If State = -1
			UITK::Disable(ButtonRemoveImage, #True)
			If CountGadgetItems(ImageList) = 0
				UITK::Disable(ButtonProcess, #True)
			EndIf
			SelectedImagePath = "" 
		Else
			*Data = GetGadgetItemData(ImageList, State)
			SelectedImagePath = *Data\File
			UITK::Disable(ButtonRemoveImage, #False)
		EndIf
		
		Preview::Update()
	EndProcedure
	
	Procedure Handler_ImageList_Forceful()
		Preview::Open(#True)
	EndProcedure
	
	Procedure Handler_ImageList_Keyboard()
		If GetGadgetAttribute(ImageList, #PB_Canvas_Key) = #PB_Shortcut_Delete
			If GetGadgetState(ImageList) > - 1
				Handler_RemoveImage()
			EndIf
		EndIf
	EndProcedure
	
	Procedure Handler_AddImage()
		Protected Result.s, File.s
		          
		File = OpenFileRequester("Choose images to add the the queue", "", "Supported files | *.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff;*.tga | All files | *.*", 0, #PB_Requester_MultiSelection)
		
		If File
			Result = File
			File = NextSelectedFileName()
			
			While File
				Result + #LF$ + File
				File = NextSelectedFileName()
			Wend
			
			AddImageToQueue(Result)
		EndIf
	EndProcedure
	
	Procedure Handler_AddFolder()
		Protected Folder.s, Result.s
		
		Folder = PathRequester("Add a folder to the queue", "")
		
		If Folder
			Result = BrowseFolder(Folder)
		EndIf
		
		If Result
			AddImageToQueue(Result)
		EndIf
	EndProcedure
	
	Procedure Handler_RemoveImage()
		Protected State = GetGadgetState(ImageList), *Data.OriginalImageInfo = GetGadgetItemData(ImageList, State)
		
		If *Data\ImageID = ImageLoadingID
			*Data\Image = -1
		Else
			If *Data\Image
				*Data\ImageID = ImageID(ImageError)
				FreeImage(*Data\Image)
			EndIf
			FreeStructure(*Data)
		EndIf
		
		RemoveGadgetItem(ImageList, State)
			
	EndProcedure
	
	Procedure Handler_TaskList()
		SelectedTaskIndex = GetGadgetState(TaskList)
		
		If SelectedTaskIndex = -1
			UITK::Disable(ButtonRemoveTask, #True)
			UITK::Disable(ButtonSetupTask, #True)
			If CountGadgetItems(TaskList) = 0
				UITK::Disable(ButtonProcess, #True)
			EndIf
		Else
			UITK::Disable(ButtonRemoveTask, #False)
			UITK::Disable(ButtonSetupTask, #False)
		EndIf
		
		Preview::Update()
	EndProcedure
	
	Procedure Handler_TaskList_Keyboard()
		If GetGadgetAttribute(TaskList, #PB_Canvas_Key) = #PB_Shortcut_Delete
			If GetGadgetState(TaskList) > - 1
				Handler_RemoveTask()
			EndIf
		EndIf
	EndProcedure
	
	Procedure Handler_NewTask()
		HideGadget(TaskContainer, #True)
		HideGadget(NewTaskContainer, #False)
	EndProcedure
	
	Procedure Handler_SetupTask()
		Protected *Data.TaskListInfo = GetGadgetItemData(TaskList, GetGadgetState(TaskList))
		OpenGadgetList(TaskSettingContainer)
		Tasks::Task(*Data\TaskID)\Populate(*Data\TaskSettings)
		CloseGadgetList()
		HideGadget(TaskContainer, #True)
		HideGadget(TaskSettingContainer, #False)
		SetupingTask = #True
	EndProcedure
	
	Procedure Handler_RemoveTask()
		Protected State = GetGadgetState(TaskList), *Data.TaskListInfo = GetGadgetItemData(TaskList, State)
		
		FreeMemory(*Data\TaskSettings)
		FreeStructure(*Data)
		RemoveGadgetItem(TaskList, State)
	EndProcedure
	
	Procedure Handler_NewTaskButton()
		Protected *Data.TaskListInfo = AllocateStructure(TaskListInfo), *OriginalData.AddListInfo
		*OriginalData = GetGadgetItemData(NewTaskList, GetGadgetState(NewTaskList))
		
		*Data\Description = *OriginalData\Description
		*Data\TaskID = *OriginalData\TaskID
		*Data\ImageID = *OriginalData\ImageID
		*Data\TaskSettings = AllocateMemory(MemorySize(Tasks::Task(*Data\TaskID)\DefaultSettings))
		CopyMemory(Tasks::Task(*Data\TaskID)\DefaultSettings, *Data\TaskSettings, MemorySize(Tasks::Task(*Data\TaskID)\DefaultSettings))
		SetGadgetItemData(TaskList, AddGadgetItem(TaskList, -1, Tasks::Task(*Data\TaskID)\Name), *Data)
		
		If CountGadgetItems(ImageList)
			UITK::Disable(ButtonProcess, #False)
		EndIf
		
		Handler_NewTaskReturn()
	EndProcedure
	
	Procedure Handler_NewTaskReturn()
		HideGadget(TaskContainer, #False)
		HideGadget(NewTaskContainer, #True)
	EndProcedure
	
	Procedure Handler_NewTaskCombo()
		Populate_TaskList(GetGadgetState(NewTaskCombo))
	EndProcedure
	
	Procedure Handler_NewTaskList()
		UITK::Disable(NewTaskButton, Bool(GetGadgetState(NewTaskList) = -1))
	EndProcedure
	
	Procedure Handler_TaskSettingReturn()
		Protected *Data.TaskListInfo = GetGadgetItemData(TaskList, GetGadgetState(TaskList))
		
		Tasks::Task(*Data\TaskID)\CleanUp()
		HideGadget(TaskSettingContainer, #True)
		HideGadget(TaskContainer, #False)
		SetupingTask = #False
	EndProcedure
	
	Procedure Handler_Menu_Preview()
		Preview::Open()
	EndProcedure
	
	Procedure Handler_Close()
		TerminateProcess_(OpenProcess_(#PROCESS_TERMINATE, #False, GetCurrentProcessId_()), 0) ;< I clearly have issues with my windows, but killing the process is a valid workaround for my own ineptitude.
	EndProcedure
	
	Procedure Thread_LoadMiniature(Null)
		Protected *Data.OriginalImageInfo, File.s, Finished = #False, Image, FinalImage, Width, Height, ImageWidth, ImageHeight, X, Y
		
		Repeat
		LockMutex(PreviewMutex)
		FirstElement(PreviewList())
		*Data = PreviewList()\Data
		File = PreviewList()\File
		DeleteElement(PreviewList())
		
		If ListSize(PreviewList()) = 0
			MiniatureThreat = 0
			Finished = #True
		EndIf
		UnlockMutex(PreviewMutex)
		
		
		If *Data\Image = 0
			Image = LoadImage(#PB_Any, File)
			
			If Image
				FinalImage = CreateImage(#PB_Any, 94, 70, 24, FixColor($202225))
				Width = ImageWidth(Image)
				Height = ImageHeight(Image)
				*Data\Information = Str(Width)+"*"+Height+" - "+ImageDepth(Image)+"bits"
				
				If Width <= 94 And Height <= 70
					ImageWidth = Width
					ImageHeight = Height
				Else
					If Round(Width / 94, #PB_Round_Nearest) < Round(Height / 70, #PB_Round_Nearest)
						ImageWidth = General::Max(1, Round(70 / Height * Width, #PB_Round_Nearest))
						ImageHeight = General::Min(70, Height)
					Else
						ImageWidth = General::Min(94, Width)
						ImageHeight = General::Max(1, Round(94 / Width * Height, #PB_Round_Nearest))
					EndIf
						ResizeImage(Image, ImageWidth, ImageHeight, #PB_Image_Smooth)
				EndIf
				
				X =  (94 - ImageWidth) * 0.5
				Y = (70 - ImageHeight) * 0.5
				
				
				StartDrawing(ImageOutput(FinalImage))
				ClipOutput(X, Y, ImageWidth, ImageHeight) 
				DrawImage(ImageID(PreviewCheckerboard), X, Y)
				DrawAlphaImage(ImageID(Image), X, Y)
				StopDrawing()
				FreeImage(Image)
				
				*Data\ImageID = ImageID(FinalImage)
				*Data\Image = FinalImage
				
			Else
				*Data\Information = Language(#lng_Error_Loading)
				*Data\ImageID = ImageID(ImageError)
			EndIf
		Else
			FreeStructure(*Data)
		EndIf
			
		SetGadgetItemData(ImageList, 0, GetGadgetItemData(ImageList, 0))
		
		Delay(10)
		
		Until Finished
	EndProcedure
	
	Procedure Populate_TaskList(Type)
		Protected Loop, Count, *Data.AddListInfo
		
 		UITK::Freeze(NewTaskList, #True)
		Count = CountGadgetItems(NewTaskList) -1
		For Loop = 0 To Count
			*Data = GetGadgetItemData(NewTaskList, 0)
			If *Data
				FreeStructure(*Data)
			EndIf
			RemoveGadgetItem(NewTaskList, 0)
		Next
		
		Count = Tasks::#__Task_Count - 1
		For Loop = 0 To Count
			If Tasks::Task(Loop)\Type = Type Or Type = 0
				
				*Data = AllocateStructure(AddListInfo)
				*Data\Description = Tasks::Task(Loop)\Description
				*Data\ImageID = Tasks::Task(Loop)\IconID
				*Data\TaskID = Loop
				SetGadgetItemData(NewTaskList, AddGadgetItem(NewTaskList, -1, Tasks::Task(Loop)\Name), *Data)
			EndIf
		Next
		
		UITK::Freeze(NewTaskList, #False)
	EndProcedure
	
	Procedure AddImageToQueue(FileList.s)
		Protected File.s, Path.s, Count, Loop, *Data.OriginalImageInfo, NewImageToProcess
		
		Count = CountString(FileList, #LF$) + 1
		
		LockMutex(PreviewMutex)
		LastElement(PreviewList())
		
		For Loop = 1 To Count
			File = StringField(FileList, Loop, #LF$)
			
			If FileSize(File) > -2
				If FindString(#SupportedFileTypes, LCase(GetExtensionPart(File)))
					NewImageToProcess = #True
					
					*Data = AllocateStructure(OriginalImageInfo)
					*Data\ImageID = ImageLoadingID
					*Data\Information = "Loading..."
					Path = GetPathPart(File)
					*Data\Path = Left(Path, Len(Path) -1)
					*Data\File = File
					
					SetGadgetItemData(ImageList, AddGadgetItem(ImageList, -1, GetFilePart(File)), *Data)
					AddElement(PreviewList())
					PreviewList()\Data = *Data
					PreviewList()\File = File
				EndIf
			Else
				If Not (Right(File, 1) = "\" Or Right(File, 1) = "/")
					File + "\"
				EndIf
				
				FileList + BrowseFolder(File)
				Count = CountString(FileList, #LF$) + 1
			EndIf
 		Next
 		
 		If MiniatureThreat = 0 And NewImageToProcess
 			MiniatureThreat = CreateThread(@Thread_LoadMiniature(), #Null)
 		EndIf
 		
 		If CountGadgetItems(ImageList) And CountGadgetItems(TaskList)
			UITK::Disable(ButtonProcess, #False)
		EndIf
 		
 		UnlockMutex(PreviewMutex)
	EndProcedure
	
	Procedure NewTaskToQueue(Task)
		
	EndProcedure
	
	Procedure.s BrowseFolder(Folder.s)
		Protected Directory = ExamineDirectory(#PB_Any, Folder, "*.*"), Result.s, Item.s
		
		While NextDirectoryEntry(Directory)
			Item = DirectoryEntryName(Directory)
			If Not (Item = "." Or Item = "..")
				If FileSize(Folder + Item) = -2
					Result + #LF$ + BrowseFolder(Folder + Item + "/")
				Else
					Result + #LF$ + Folder + Item
				EndIf
			EndIf
		Wend
		
		FinishDirectory(Directory)
		
		ProcedureReturn Result
	EndProcedure
	;}
	
	DataSection
		Icon:
		IncludeBinary "../Media/Icon/Icon18.png"
		
		English:
		IncludeFile "../Language/MainWindow/English.txt"
		
		French:
		IncludeFile "../Language/MainWindow/Français.txt"
		
	EndDataSection
EndModule


































; IDE Options = PureBasic 6.00 Beta 9 (Windows - x64)
; CursorPosition = 788
; FirstLine = 12
; Folding = thAAAA9
; EnableXP
; DPIAware