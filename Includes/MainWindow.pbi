Module MainWindow
	EnableExplicit
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
	
	Macro SetButtonColor(Button, Parent, BackCold, Back_Warm, BackHot, TextWarm, TextHot, ToolTip)
		SetGadgetFont(Button, UITK::UITKFont)
		SetGadgetAttribute(Button, UITK::#Attribute_TextScale, 24)
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
	EndStructure
	
	Structure AddListInfo
		ImageID.i
		Description.s
		TaskID.w		;.w is quite optimist there xD
	EndStructure
	
	Structure TaskListInfo Extends AddListInfo
		*TaskSettings
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
	
	Global Window, ImageList, ButtonAddImage, ButtonAddFolder, ButtonRemoveImage, TaskList, ButtonAddTask, ButtonSetupTask, ButtonRemoveTask, ButtonProcess, NewTaskContainer, NewTaskReturnButton, NewTaskCombo, NewTaskList, NewTaskButton
	Global TaskSettingContainer, TaskSettingReturnButton, NewList TaskSettingList()
	Global BoldFont = FontID(LoadFont(#PB_Any, "Segoe UI", 9, #PB_Font_HighQuality | #PB_Font_Bold))
	Global ImageLoading, ImageError, ImageLoadingID
	Global PreviewMutex, PreviewThread, NewList PreviewList.PreviewLoading()
	
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
	
	#MenuBar_Height = 0
	#Window_Margin = 12
	#Window_Height = 500
	#Window_Width = 950
	#ImageList_Width = 400
	#Iconbar_Size = 30
	#Iconbar_Offset = 5
	#ButtonBack_Size = 30
	;}
	
	;{ Private procedures declaration
	Declare ImageList_ItemRedraw(*Item.ImageListItem, X, Y, Width, Height, State)
	Declare TaskList_ItemRedraw(*Item.AddListItem, X, Y, Width, Height, State)
	
	Declare Handler_Drop()
	Declare Handler_ImageList()
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
	
	Declare Handler_TaskSettingReturn()
	
	Declare Handler_Close()
	
	Declare Thread_LoadPreview(Null)
	
	Declare Populate_TaskList(Type)
	Declare AddImageToQueue(File.s)
	Declare NewTaskToQueue(Task)
	Declare.s BrowseFolder(Folder.s)
	
	
	;}
	
	; Public procedures
	Procedure Open()
		Window = UITK::Window(#PB_Any, 0, 0, #Window_Width, #Window_Height, General::#AppName, UITK::#DarkMode | UITK::#Window_CloseButton | #PB_Window_ScreenCentered | #PB_Window_Invisible)
		BindEvent(#PB_Event_CloseWindow, @Handler_Close(), Window)
		UITK::SetWindowIcon(Window, CatchImage(#PB_Any, ?Icon))
		BindEvent(#PB_Event_GadgetDrop, @Handler_Drop())
		
		ImageList = UITK::VerticalList(#PB_Any, #Window_Margin, #MenuBar_Height + #Window_Margin, #ImageList_Width, #Window_Height - #MenuBar_Height - #Window_Margin * 2, UITK::#VList_Toolbar | UITK::#ReOrder, @ImageList_ItemRedraw())
		SetGadgetAttribute(ImageList, UITK::#Attribute_CornerRadius, 5)
		SetGadgetAttribute(ImageList, UITK::#Attribute_ItemHeight, 90)
		EnableGadgetDrop(ImageList, #PB_Drop_Files, #PB_Drag_Move)
		BindGadgetEvent(ImageList, @Handler_ImageList(), #PB_EventType_Change)
		BindGadgetEvent(ImageList, @Handler_ImageList_Keyboard(), #PB_EventType_KeyDown)
		
		ButtonAddImage = UITK::Button(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "a")
		SetButtonColor(ButtonAddImage, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, "Add images...")
		BindGadgetEvent(ButtonAddImage, @Handler_AddImage(), #PB_EventType_Change)
		
		ButtonAddFolder = UITK::Button(#PB_Any, #Iconbar_Offset * 2 + #Iconbar_Size, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "c")
		SetButtonColor(ButtonAddFolder, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, "Add folder...")
		BindGadgetEvent(ButtonAddFolder, @Handler_AddFolder(), #PB_EventType_Change)
		
		ButtonRemoveImage = UITK::Button(#PB_Any, #Iconbar_Offset * 3 + #Iconbar_Size * 2, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "b")
		SetButtonColor(ButtonRemoveImage, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $D83C3E, $E06365, $FAFAFB, $FAFAFB, "Remove selected image")
		BindGadgetEvent(ButtonRemoveImage, @Handler_RemoveImage(), #PB_EventType_Change)
		UITK::Disable(ButtonRemoveImage, #True)
		CloseGadgetList()
		
		TaskList = UITK::VerticalList(#PB_Any, #Window_Margin * 2 + #ImageList_Width, #MenuBar_Height + #Window_Margin, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2, UITK::#VList_Toolbar | UITK::#ReOrder, @TaskList_ItemRedraw())
		SetGadgetAttribute(TaskList, UITK::#Attribute_ItemHeight, 60)
		SetGadgetAttribute(TaskList, UITK::#Attribute_CornerRadius, 5)
		BindGadgetEvent(TaskList, @Handler_TaskList(), #PB_EventType_Change)
		BindGadgetEvent(TaskList, @Handler_SetupTask(), UITK::#Eventtype_ForcefulChange)
		BindGadgetEvent(TaskList, @Handler_TaskList_Keyboard(), #PB_EventType_KeyDown)
		
		ButtonAddTask = UITK::Button(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "e")
		SetButtonColor(ButtonAddTask, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, "Add Task...")
		BindGadgetEvent(ButtonAddTask, @Handler_NewTask(), #PB_EventType_Change)
		
		ButtonSetupTask = UITK::Button(#PB_Any, #Iconbar_Offset * 2 + #Iconbar_Size, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "g")
		SetButtonColor(ButtonSetupTask, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, "Task settings...")
		UITK::Disable(ButtonSetupTask, #True)
		BindGadgetEvent(ButtonSetupTask, @Handler_SetupTask(), #PB_EventType_Change)
		
		ButtonRemoveTask = UITK::Button(#PB_Any, #Iconbar_Offset * 3 + #Iconbar_Size * 2, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "f")
		SetButtonColor(ButtonRemoveTask, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $D83C3E, $E06365, $FAFAFB, $FAFAFB, "Remove selected Task")
		UITK::Disable(ButtonRemoveTask, #True)
		BindGadgetEvent(ButtonRemoveTask, @Handler_RemoveTask(), #PB_EventType_Change)
		
		ButtonProcess = UITK::Button(#PB_Any, #Iconbar_Offset * 4 + #Iconbar_Size * 3, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "h")
		SetButtonColor(ButtonProcess, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $3AA55D, $6BD08B, $FAFAFB, $FAFAFB, "Start")
		UITK::Disable(ButtonProcess, #True)
		CloseGadgetList()
		
		NewTaskContainer = UITK::Container(#PB_Any, #Window_Margin * 2 + #ImageList_Width, #MenuBar_Height + #Window_Margin, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2)
		SetGadgetAttribute(NewTaskContainer, UITK::#Attribute_CornerRadius, 5)
		HideGadget(NewTaskContainer, #True)
		
		TaskContainerWidth = GadgetWidth(NewTaskContainer)
		TaskContainerBackColor = GetGadgetColor(NewTaskContainer, UITK::#Color_Shade_Cold)
		TaskContainerFrontColor = GetGadgetColor(NewTaskContainer, UITK::#Color_Text_Cold)
		TaskContainerGadgetWidth = TaskContainerWidth - Tasks::#TextWidth - Tasks::#Margin * 3
		
		NewTaskCombo = UITK::Combo(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, 200, #ButtonBack_Size, UITK::#Border)
		
		SetGadgetColor(NewTaskCombo, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskCombo, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(NewTaskCombo, UITK::#Color_Back_Cold), 255))
		
		AddGadgetItem(NewTaskCombo, #TaskType_All, "All")
		AddGadgetItem(NewTaskCombo, #TaskType_Colors, "Colors")
		AddGadgetItem(NewTaskCombo, #TaskType_Transformation, "Transformation")
		AddGadgetItem(NewTaskCombo, #TaskType_PixelArt, "Pixel Art")
		AddGadgetItem(NewTaskCombo, #TaskType_Other, "Other")
		SetGadgetState(NewTaskCombo, 0)
		BindGadgetEvent(NewTaskCombo, @Handler_NewTaskCombo(), #PB_EventType_Change)
		
		NewTaskList = UITK::VerticalList(#PB_Any, #Iconbar_Offset, #Iconbar_Offset * 2 + #ButtonBack_Size, TaskContainerWidth - #Iconbar_Offset * 2, GadgetHeight(NewTaskContainer) - #Iconbar_Offset * 4 - #ButtonBack_Size * 2, UITK::#Default, @TaskList_ItemRedraw())
		BindGadgetEvent(NewTaskList, @Handler_NewTaskList(), #PB_EventType_Change)
		BindGadgetEvent(NewTaskList, @Handler_NewTaskButton(), UITK::#Eventtype_ForcefulChange)
		SetGadgetAttribute(NewTaskList, UITK::#Attribute_ItemHeight, 60)
		SetGadgetAttribute(NewTaskList, UITK::#Attribute_SortItems, #True)
		Populate_TaskList(0)
		
		NewTaskReturnButton = UITK::Button(#PB_Any, TaskContainerWidth - 150 - #Iconbar_Offset, GadgetHeight(NewTaskContainer) - #Iconbar_Offset - #ButtonBack_Size, 150, #ButtonBack_Size, "Cancel", UITK::#Border)
		BindGadgetEvent(NewTaskReturnButton, @Handler_NewTaskReturn(), #PB_EventType_Change)
		SetGadgetAttribute(NewTaskReturnButton, #PB_Canvas_Cursor, #PB_Cursor_Hand)
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Back_Cold, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Warm), 255))
		SetGadgetColor(NewTaskReturnButton, UITK::#Color_Back_Hot, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Hot), 255))
		
		NewTaskButton = UITK::Button(#PB_Any, TaskContainerWidth - 300 - #Iconbar_Offset * 2, GadgetHeight(NewTaskContainer) - #Iconbar_Offset - #ButtonBack_Size, 150, #ButtonBack_Size, "Add to the queue", UITK::#Border)
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
		
		TaskSettingReturnButton =  UITK::Button(#PB_Any, TaskContainerWidth - 100 - #Iconbar_Offset, GadgetHeight(NewTaskContainer) - #Iconbar_Offset - #ButtonBack_Size, 100, #ButtonBack_Size, "Back", UITK::#Border)
 		BindGadgetEvent(TaskSettingReturnButton, @Handler_TaskSettingReturn(), #PB_EventType_Change)
		SetGadgetAttribute(TaskSettingReturnButton, #PB_Canvas_Cursor, #PB_Cursor_Hand)
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Parent, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Back_Cold, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), 255))
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Back_Warm, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Warm), 255))
		SetGadgetColor(TaskSettingReturnButton, UITK::#Color_Back_Hot, SetAlpha(GetGadgetColor(ImageList, UITK::#Color_Shade_Hot), 255))
		
		CloseGadgetList()
		
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
			DrawVectorParagraph("Informations:", 200, 20)
			InformationWidth = VectorTextWidth("Informations:")
			
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
		If GetGadgetState(ImageList) = -1
			UITK::Disable(ButtonRemoveImage, #True)
			If CountGadgetItems(ImageList) = 0
				UITK::Disable(ButtonProcess, #True)
			EndIf
		Else
			UITK::Disable(ButtonRemoveImage, #False)
		EndIf
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
		If GetGadgetState(TaskList) = -1
			UITK::Disable(ButtonRemoveTask, #True)
			UITK::Disable(ButtonSetupTask, #True)
			If CountGadgetItems(TaskList) = 0
				UITK::Disable(ButtonProcess, #True)
			EndIf
		Else
			UITK::Disable(ButtonRemoveTask, #False)
			UITK::Disable(ButtonSetupTask, #False)
		EndIf
	EndProcedure
	
	Procedure Handler_TaskList_Keyboard()
		If GetGadgetAttribute(TaskList, #PB_Canvas_Key) = #PB_Shortcut_Delete
			If GetGadgetState(TaskList) > - 1
				Handler_RemoveTask()
			EndIf
		EndIf
	EndProcedure
	
	Procedure Handler_NewTask()
		HideGadget(TaskList, #True)
		HideGadget(NewTaskContainer, #False)
	EndProcedure
	
	Procedure Handler_SetupTask()
		Protected *Data.TaskListInfo = GetGadgetItemData(TaskList, GetGadgetState(TaskList))
		HideGadget(TaskList, #True)
		HideGadget(TaskSettingContainer, #False)
		OpenGadgetList(TaskSettingContainer)
		
		Tasks::Task(*Data\TaskID)\Populate(*Data\TaskSettings)
		
		CloseGadgetList()
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
		HideGadget(TaskList, #False)
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
		HideGadget(TaskList, #False)
	EndProcedure
	
	Procedure Handler_Close()
		Protected phandle, Result
		phandle = OpenProcess_(#PROCESS_TERMINATE, #False, GetCurrentProcessId_()) ;< I clearly have issues with my windows, but killing the process is a valid workaround for my own ineptitude.
		TerminateProcess_(phandle, @Result)
	EndProcedure
	
	Procedure Thread_LoadPreview(Null)
		Protected *Data.OriginalImageInfo, File.s, Finished = #False, Image, FinalImage, Width, Height
		
		Repeat
		LockMutex(PreviewMutex)
		FirstElement(PreviewList())
		*Data = PreviewList()\Data
		File = PreviewList()\File
		DeleteElement(PreviewList())
		
		If ListSize(PreviewList()) = 0
			PreviewThread = 0
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
				
				If ImageWidth(Image) <= 94 And ImageHeight(Image) <= 70
					
				ElseIf Round(ImageWidth(Image) / 94, #PB_Round_Nearest) < Round(ImageHeight(Image) / 70, #PB_Round_Nearest)
					ResizeImage(Image, General::Max(1, Round(70 / ImageHeight(Image) * ImageWidth(Image), #PB_Round_Nearest)), 70, #PB_Image_Smooth)
				Else
					ResizeImage(Image, 94, General::Max(1, Round(94 / ImageWidth(Image) * ImageHeight(Image), #PB_Round_Nearest)), #PB_Image_Smooth)
				EndIf
				
				StartDrawing(ImageOutput(FinalImage))
				DrawAlphaImage(ImageID(Image), (94 - ImageWidth(Image)) * 0.5, (70 - ImageHeight(Image)) * 0.5)
				StopDrawing()
				FreeImage(Image)
				
				*Data\ImageID = ImageID(FinalImage)
				*Data\Image = FinalImage
				
			Else
				*Data\Information = "Couldn't load the image"
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
 		
 		If PreviewThread = 0 And NewImageToProcess
 			PreviewThread = CreateThread(@Thread_LoadPreview(), #Null)
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
	EndDataSection
EndModule


































; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 438
; FirstLine = 27
; Folding = tpAADA-
; EnableXP