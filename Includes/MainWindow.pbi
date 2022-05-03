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
		SetGadgetFont(Button, MaterialFont)
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
	
	; Private variables, structures and constants
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
	
	Structure VerticalListItem
		Text.UITK::Text
		*Data.OriginalImageInfo
	EndStructure
	
	Global Window, ImageList, ButtonAddImage, ButtonAddFolder, ButtonRemoveImage, FilterList, ButtonAddFilter, ButtonSetupFilter, ButtonRemoveFilter, ButtonProcess
	Global MaterialFont = FontID(LoadFont(#PB_Any, "UITK Icon Font", 18, #PB_Font_HighQuality))
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
	
	; Private procedures declaration
	Declare VerticalList_ItemRedraw(*Item.VerticalListItem, X, Y, Width, Height, State)
	Declare Handler_Drop()
	Declare Handler_AddImage()
	Declare Handler_AddFolder()
	Declare Handler_RemoveImage()
	Declare Handler_ImageList()
	Declare Handler_FilterList()
	Declare Thread_LoadPreview(Null)
	Declare AddImageToQueue(File.s)
	Declare.s BrowseFolder(Folder.s)
	
	;{ Public procedures
	Procedure Open()
		Window = UITK::Window(#PB_Any, 0, 0, #Window_Width, #Window_Height, General::#AppName, UITK::#DarkMode | UITK::#Window_CloseButton | #PB_Window_ScreenCentered)
		UITK::SetWindowIcon(Window, CatchImage(#PB_Any, ?Icon))
		BindEvent(#PB_Event_GadgetDrop, @Handler_Drop())
		
		ImageList = UITK::VerticalList(#PB_Any, #Window_Margin, #MenuBar_Height + #Window_Margin, #ImageList_Width, #Window_Height - #MenuBar_Height - #Window_Margin * 2, UITK::#VList_Toolbar, @VerticalList_ItemRedraw())
		SetGadgetAttribute(ImageList, UITK::#Properties_CornerRadius, 5)
		SetGadgetAttribute(ImageList, UITK::#Properties_ItemHeight, 90)
		EnableGadgetDrop(ImageList, #PB_Drop_Files, #PB_Drag_Move)
		BindGadgetEvent(ImageList, @Handler_ImageList(), #PB_EventType_Change)
		
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
		
		FilterList = UITK::VerticalList(#PB_Any, #Window_Margin * 2 + #ImageList_Width, #MenuBar_Height + #Window_Margin, #Window_Width - (#Window_Margin * 3 + #ImageList_Width), #Window_Height - #MenuBar_Height - #Window_Margin * 2, UITK::#VList_Toolbar)
		SetGadgetAttribute(FilterList, UITK::#Properties_CornerRadius, 5)
		BindGadgetEvent(FilterList, @Handler_FilterList(), #PB_EventType_Change)
		
		ButtonAddFilter = UITK::Button(#PB_Any, #Iconbar_Offset, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "e")
		SetButtonColor(ButtonAddFilter, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, "Add Filter...")
		
		ButtonSetupFilter = UITK::Button(#PB_Any, #Iconbar_Offset * 2 + #Iconbar_Size, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "g")
		SetButtonColor(ButtonSetupFilter, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $5865F2, $7984F5, $FAFAFB, $FAFAFB, "Filter settings...")
		
		ButtonRemoveFilter = UITK::Button(#PB_Any, #Iconbar_Offset * 3 + #Iconbar_Size * 2, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "f")
		SetButtonColor(ButtonRemoveFilter, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $D83C3E, $E06365, $FAFAFB, $FAFAFB, "Remove selected Filter")
		UITK::Disable(ButtonRemoveFilter, #True)
		
		ButtonProcess = UITK::Button(#PB_Any, #Iconbar_Offset * 4 + #Iconbar_Size * 3, #Iconbar_Offset, #Iconbar_Size, #Iconbar_Size, "h")
		SetButtonColor(ButtonProcess, GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), GetGadgetColor(ImageList, UITK::#Color_Shade_Cold), $3AA55D, $6BD08B, $FAFAFB, $FAFAFB, "Start")
		UITK::Disable(ButtonProcess, #True)
		CloseGadgetList()
	EndProcedure
	;}
	
	;{ Private procedures
	Procedure VerticalList_ItemRedraw(*Item.VerticalListItem, X, Y, Width, Height, State)
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
			DrawVectorParagraph(*Item\Data\Path, 200, 20)
			
			MovePathCursor(X + 118 + InformationWidth, Y + 57)
			DrawVectorParagraph(*Item\Data\Information, 200, 20)
		EndIf
	EndProcedure
	
	Procedure Handler_Drop()
		AddImageToQueue(EventDropFiles())
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
			FreeStructure(*Data)
		EndIf
		
		RemoveGadgetItem(ImageList, State)
			
	EndProcedure
	
	Procedure Handler_ImageList()
		Protected State = GetGadgetState(ImageList)
		
		If State = -1
			UITK::Disable(ButtonRemoveImage, #True)
		Else
			UITK::Disable(ButtonRemoveImage, #False)
		EndIf
	EndProcedure
	
	Procedure Handler_FilterList()
		
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
					AddGadgetItem(ImageList, -1, GetFilePart(File))
					*Data = AllocateStructure(OriginalImageInfo)
					*Data\ImageID = ImageLoadingID
					*Data\Information = "Loading..."
					Path = GetPathPart(File)
					*Data\Path = Left(Path, Len(Path) -1)
					
					SetGadgetItemData(ImageList, CountGadgetItems(ImageList) - 1, *Data)
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
 		
 		UnlockMutex(PreviewMutex)
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
; CursorPosition = 59
; Folding = tNA5
; EnableXP