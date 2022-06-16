Module Preview
	EnableExplicit
	
	Enumeration 1 ;Packet identifier
		#NewImage
		#BatchProcess
		#FinalProcess
		#FreeCurrentImagePreviousTask
		#BatchDone
		#Result
	EndEnumeration
	
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
	
	#CornerSize = 5
	
	Structure ResizeData
		Image.i
		Width.i
		Height.i
	EndStructure
	
	Global Container, Width = 800, Height = 600, X = -1, Y = -1
	Global WindowColor, GadgetColor, Canvas
	
	Global ImagePath.s, OriginalImage.i, WorkImage.i, PreviewImage.i, ResizedImage.i
	Global CanvasHeight, CanvasWidth, DisplayedWidth, DisplayedHeight
	Global LoadingImage = CatchImage(#PB_Any, ?Loading)
	Global BusyThread, NextWork, ResizeThread, NextResize, CheckerboardPattern
	
	;Private procedure declaration
	Declare Handler_WindowClose()
	Declare Handler_WindowResize()
	Declare Handler_FinishPreviewBatch()
	Declare Handler_FinishCurrentTask()
	Declare Handler_FinishResize()
	Declare Redraw()
	Declare ProcessCurrentTask()
	Declare ResizeThread(*ResizeData.ResizeData)
	Declare Checkerboard(*ResizeData.ResizeData)
	
	;Public procedure
	Procedure Open(Forced = #False)
		If Window
			If Not Forced
				Handler_WindowClose()
			EndIf
		Else
			ExamineDesktops()
			Select General::Language
				Case "français"
					Window = UITK::Window(#PB_Any, X, Y, Width, Height, General::#AppName + " Aperçu", UITK::#Window_CloseButton | #PB_Window_SizeGadget | (Bool(X = -1 And Y = -1) * #PB_Window_ScreenCentered) | #PB_Window_Invisible | General::ColorMode)
				Default
					Window = UITK::Window(#PB_Any, X, Y, Width, Height, General::#AppName + " Preview", UITK::#Window_CloseButton | #PB_Window_SizeGadget | (Bool(X = -1 And Y = -1) * #PB_Window_ScreenCentered) | #PB_Window_Invisible | General::ColorMode)
			EndSelect
			UITK::SetWindowBounds(Window, 800, 600, DesktopWidth(0), DesktopHeight(0)) ; A dirty hack to avoid flickering. Can't we resize a canvas without it reverting to white?
			WindowColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Parent), 255)
			GadgetColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Shade_Cold), 255)
			
			CanvasHeight = WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin
			CanvasWidth = WindowWidth(Window) - 2 * MainWindow::#Window_Margin
			
			Container = ContainerGadget(#PB_Any, MainWindow::#Window_Margin, MainWindow::#Window_Margin, CanvasWidth, CanvasHeight, #PB_Container_BorderLess)
			
			Canvas = CanvasGadget(#PB_Any, 0, 0, DesktopWidth(0), DesktopHeight(0))
			CloseGadgetList()
			BindEvent(#PB_Event_CloseWindow, @Handler_WindowClose(), Window)
			BindEvent(#PB_Event_SizeWindow, @Handler_WindowResize(), Window)
			Resize()
			HideWindow(Window, #False)
		EndIf
		
	EndProcedure
	
	Procedure Update()
		Protected *Data.MainWindow::TaskListInfo, Loop, ImageDepthCorrection, Position, NewList TaskQueue.Tasks::Queue()
		
		; Check if the source image has changed
		If MainWindow::SelectedImagePath <> ImagePath
			If OriginalImage
				FreeImage(OriginalImage)
				OriginalImage = 0
			EndIf
			
			If PreviewImage
				FreeImage(PreviewImage)
				PreviewImage = 0
			EndIf
			
			If ResizedImage
				FreeImage(ResizedImage)
				ResizedImage = 0
			EndIf
			
			ImagePath = MainWindow::SelectedImagePath
			
			If ImagePath
				OriginalImage = LoadImage(#PB_Any, ImagePath)
			EndIf
		EndIf
		
		; Do the tasks
		If MainWindow::SelectedTaskIndex = -1
			; No task
			If PreviewImage
				FreeImage(PreviewImage)
				PreviewImage = 0
			EndIf
			
			If OriginalImage
				PreviewImage = CopyImage(OriginalImage, #PB_Any)
			EndIf
		Else
			If OriginalImage
				If MainWindow::SelectedTaskIndex > 0 And MainWindow::SetupingTask = #False
					If PreviewImage
						FreeImage(PreviewImage)
						PreviewImage = 0
					EndIf
					
 					;Process from the start up to the previous task
					For Loop = 0 To MainWindow::SelectedTaskIndex - 1
						*Data = GetGadgetItemData(MainWindow::TaskList, Loop)
						AddElement(TaskQueue())
						TaskQueue()\ID = *Data\TaskID
						TaskQueue()\Settings = *Data\TaskSettings
					Next
					
					Tasks::Process(OriginalImage, TaskQueue(), #Update_PreviousTaskDone)
					BusyThread = #True
					PreviewImage = CopyImage(LoadingImage, #PB_Any)
					
				Else
					If MainWindow::SelectedTaskIndex = 0 And WorkImage
						FreeImage(WorkImage)
						WorkImage = 0
					EndIf
					
 					ProcessCurrentTask()
				EndIf
			Else
				
			EndIf
		EndIf
		
		If Window
			Resize()
		EndIf
	EndProcedure
	
	Procedure Resize()
		Protected ImageWidth, ImageHeight, HRatio.d, VRatio.d, *ResizeData.ResizeData
		
		If PreviewImage
			ImageWidth = ImageWidth(PreviewImage)
			ImageHeight = ImageHeight(PreviewImage)
			
			If ImageWidth > CanvasWidth Or ImageHeight > CanvasHeight
				If ResizeThread
					NextResize = #True
				Else
					HRatio = CanvasWidth / ImageWidth
					VRatio = CanvasHeight / ImageHeight
					
					*ResizeData = AllocateStructure(ResizeData)
					
					If VRatio < HRatio
						*ResizeData\Height = General::Min(CanvasHeight, ImageHeight)
						*ResizeData\Width = ImageWidth * VRatio
					Else
						*ResizeData\Width = General::Min(CanvasWidth, ImageWidth)
						*ResizeData\Height = ImageHeight * HRatio
					EndIf
					
					*ResizeData\Image = CopyImage(PreviewImage, #PB_Any)
					
					ResizeThread = CreateThread(@ResizeThread(), *ResizeData)
				EndIf
			Else
				If ResizeThread
					NextResize = #True
				Else
					*ResizeData = AllocateStructure(ResizeData)
					
					*ResizeData\Width = ImageWidth
					*ResizeData\Height = ImageHeight
					*ResizeData\Image = CopyImage(PreviewImage, #PB_Any)
					
					ResizeThread = CreateThread(@ResizeThread(), *ResizeData)
				EndIf
			EndIf
		Else
			Redraw()
		EndIf
	EndProcedure
	
	;Private procedure
	Procedure Handler_WindowClose()
		Width = WindowWidth(Window)
		Height = WindowHeight(Window)
		X = WindowX(Window)
		Y = WindowY(Window)
		
		CloseWindow(Window)
		Window = 0
	EndProcedure
	
	Procedure Handler_WindowResize()
  		CanvasHeight = WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin
  		CanvasWidth = WindowWidth(Window) - 2 * MainWindow::#Window_Margin
  		Redraw()
  		SetWindowPos_(GadgetID(Container), 0, 0, 0, CanvasWidth, CanvasHeight, #SWP_NOMOVE | #SWP_NOZORDER)
	EndProcedure
	
	Procedure Handler_FinishPreviewBatch()
		If WorkImage
			FreeImage(WorkImage)
		EndIf
		
		WorkImage = EventData()
		BusyThread = #False
		ProcessCurrentTask()
	EndProcedure
	
	Procedure Handler_FinishCurrentTask()
		If PreviewImage
			FreeImage(PreviewImage)
		EndIf
		
		PreviewImage = EventData()
		
		If Window
			Resize()
		EndIf
		
		BusyThread = #False
		
		If NextWork
			NextWork = #False
			ProcessCurrentTask()
		EndIf
	EndProcedure
	
	Procedure Handler_FinishResize()
		Protected *ResizeData.ResizeData
		If ResizedImage
			FreeImage(ResizedImage)
		EndIf
		
		*ResizeData = EventData()
		ResizedImage = *ResizeData\Image
		DisplayedWidth = *ResizeData\Width
		DisplayedHeight = *ResizeData\Height
		
		FreeStructure(*ResizeData)
		
		If Window
			Redraw()
		EndIf
		
		ResizeThread = 0
		
		If NextResize
			NextResize = #False
			Resize()
		EndIf
	EndProcedure
	
	Procedure Redraw()
		; Fill the background
		StartVectorDrawing(CanvasVectorOutput(Canvas))
		AddPathBox(0, 0, CanvasWidth, CanvasHeight)
		VectorSourceColor(GadgetColor)
		FillPath(#PB_Path_Preserve)
		
		; Draw the preview
		If ResizedImage
			MovePathCursor((CanvasWidth - DisplayedWidth) * 0.5, (CanvasHeight - DisplayedHeight) * 0.5)
			DrawVectorImage(ImageID(ResizedImage))
		EndIf
		
		; Draw the corners.
		UITK::AddPathRoundedBox(0, 0, CanvasWidth, CanvasHeight, 5)
		VectorSourceColor(WindowColor)
		FillPath()
		
		StopVectorDrawing()
	EndProcedure
	
	Procedure ProcessCurrentTask()
		Protected *Data.MainWindow::TaskListInfo, Position, NewList TaskQueue.Tasks::Queue()
		
		If Not BusyThread
			BusyThread = #True
			*Data = GetGadgetItemData(MainWindow::TaskList, MainWindow::SelectedTaskIndex)
			
			AddElement(TaskQueue())
			TaskQueue()\ID = *Data\TaskID
			TaskQueue()\Settings = *Data\TaskSettings
			
			If WorkImage = 0
				Tasks::Process(OriginalImage, TaskQueue(), #Update_CurrentTaskDone)
			Else
				Tasks::Process(WorkImage, TaskQueue(), #Update_CurrentTaskDone)
			EndIf
		Else
			NextWork = #True
		EndIf
	EndProcedure
	
	Procedure Checkerboard(*ResizeData.ResizeData)
		Protected TempImage
		
		TempImage = CopyImage(*ResizeData\Image, #PB_Any)
		
		StartVectorDrawing(ImageVectorOutput(*ResizeData\Image))
		AddPathBox(0, 0, VectorOutputWidth(), VectorOutputHeight())
		VectorSourceImage(ImageID(CheckerboardPattern), 255, 16, 15, #PB_VectorImage_Repeat)
		FillPath()
		MovePathCursor(0, 0)
		DrawVectorImage(ImageID(TempImage))
		StopVectorDrawing()
		
		FreeImage(TempImage)
		
		PostEvent(#Update_Resize, 0, 0, 0, *ResizeData)
	EndProcedure
	
	Procedure ResizeThread(*ResizeData.ResizeData)
		ResizeImage(*ResizeData\Image, *ResizeData\Width, *ResizeData\Height, #PB_Image_Smooth)
		Checkerboard(*ResizeData)
	EndProcedure
	
	BindEvent(#Update_PreviousTaskDone, @Handler_FinishPreviewBatch())
	BindEvent(#Update_CurrentTaskDone, @Handler_FinishCurrentTask())
	BindEvent(#Update_Resize, @Handler_FinishResize())
	
	CheckerboardPattern = CreateImage(#PB_Any, 16, 16, 24, $FFFFFF)
	StartVectorDrawing(ImageVectorOutput(CheckerboardPattern))
	AddPathBox(0, 0, 8, 8)
	AddPathBox(8, 8, 8, 8)
	VectorSourceColor(SetAlpha($BFBFBF, 255))
	FillPath()
	StopVectorDrawing()
	
	DataSection
		Loading:
		IncludeBinary "../Media/Loading.png"
	EndDataSection
EndModule
; IDE Options = PureBasic 6.00 Beta 9 (Windows - x64)
; CursorPosition = 44
; FirstLine = 7
; Folding = BAA-
; EnableXP
; DPIAware