Module Preview
	EnableExplicit
	
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
	
	Global Container, Width = 800, Height = 600, X = -1, Y = -1
	Global WindowColor, GadgetColor, Canvas
	
	Global CurrentImagePath.s, CurrentImageSource.i, CurrentImagePreviousTask.i, CurrentImage.i, PreviewImage.i, CurrentTaskID.i
	Global CanvasHeight, CanvasWidth, PreviewImageWidth, PreviewImageHeight, DisplayedWidth, DisplayedHeight
	
	;Private procedure declaration
	Declare Handler_WindowClose()
	Declare Handler_WindowResize()
	
	Declare Redraw()
	
	;Public procedure
	Procedure Open(Forced = #False)
		If Window
			If Not Forced
				Handler_WindowClose()
			EndIf
		Else
			ExamineDesktops()
			Window = UITK::Window(#PB_Any, X, Y, Width, Height, General::#AppName + " Preview", UITK::#Window_CloseButton | #PB_Window_SizeGadget | (Bool(X = -1 And Y = -1) * #PB_Window_ScreenCentered) | #PB_Window_Invisible | General::ColorMode)
			UITK::SetWindowBounds(Window, 800, 600, DesktopWidth(0), DesktopHeight(0)) ; A dirty hack to avoid flickering. Can't we resize a canvas without it reverting to white?
			WindowColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Parent), 255)
			GadgetColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Shade_Cold), 255)
			
			Container = ContainerGadget(#PB_Any, MainWindow::#Window_Margin, MainWindow::#Window_Margin, WindowWidth(Window) - 2 * MainWindow::#Window_Margin, WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin, #PB_Container_BorderLess)
			
			Canvas = CanvasGadget(#PB_Any, 0, 0, DesktopWidth(0), DesktopHeight(0))
			CloseGadgetList()
			BindEvent(#PB_Event_CloseWindow, @Handler_WindowClose(), Window)
			BindEvent(#PB_Event_SizeWindow, @Handler_WindowResize(), Window)
			Handler_WindowResize()
			Resize()
			HideWindow(Window, #False)
		EndIf
		
	EndProcedure
	
	Procedure Update()
		If MainWindow::SelectedImagePath <> CurrentImagePath
			If CurrentImageSource
				FreeImage(CurrentImageSource)
				CurrentImageSource = 0
			EndIf
			
			If CurrentImagePreviousTask
				FreeImage(CurrentImagePreviousTask)
				CurrentImagePreviousTask = 0
			EndIf
			
			If CurrentImage
				FreeImage(CurrentImage)
				CurrentImage = 0
			EndIf
			
			If PreviewImage
				FreeImage(PreviewImage)
				PreviewImage = 0
			EndIf
			
			CurrentImagePath = MainWindow::SelectedImagePath
			
		EndIf
		
		If CurrentImagePath
			CurrentImageSource = LoadImage(#PB_Any, CurrentImagePath)
		EndIf
		
		; Do the tasks
		If CurrentImageSource
			CurrentImage = CopyImage(CurrentImageSource, #PB_Any)
		EndIf
		
		If Window
			Resize()
		EndIf
	EndProcedure
	
	Procedure Resize()
		Protected ImageWidth, ImageHeight, HRatio.d, VRatio.d
		
		If CurrentImage
			ImageWidth = ImageWidth(CurrentImage)
			ImageHeight = ImageHeight(CurrentImage)
			
			If ImageWidth > CanvasWidth Or ImageHeight > CanvasHeight
				HRatio = CanvasWidth / ImageWidth
				VRatio = CanvasHeight / ImageHeight
				
				If VRatio < HRatio
					DisplayedHeight = CanvasHeight
					DisplayedWidth = ImageWidth * VRatio
				Else
					DisplayedWidth = CanvasWidth
					DisplayedHeight = ImageHeight * HRatio
				EndIf
				
				If PreviewImage
					FreeImage(PreviewImage)
				EndIf
				
				PreviewImage = CopyImage(CurrentImage, #PB_Any)
				ResizeImage(PreviewImage, DisplayedWidth, DisplayedHeight, #PB_Image_Smooth)
				
			Else
				DisplayedWidth = ImageWidth
				DisplayedHeight = ImageHeight
				
				If PreviewImage
					FreeImage(PreviewImage)
				EndIf
				
				PreviewImage = CopyImage(CurrentImage, #PB_Any)
			EndIf
		EndIf
		
		Redraw()
		
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
	
	Procedure Redraw()
		
		; Fill the background
		StartVectorDrawing(CanvasVectorOutput(Canvas))
		AddPathBox(0, 0, CanvasWidth, CanvasHeight)
		VectorSourceColor(GadgetColor)
		FillPath(#PB_Path_Preserve)
		
		; Draw the preview
		If CurrentImage
			MovePathCursor((CanvasWidth - DisplayedWidth) * 0.5, (CanvasHeight - DisplayedHeight) * 0.5)
			DrawVectorImage(ImageID(PreviewImage))
		EndIf
		
		; Draw the corners.
		UITK::AddPathRoundedBox(0, 0, CanvasWidth, CanvasHeight, 5)
		VectorSourceColor(WindowColor)
		FillPath()
		
		StopVectorDrawing()
	EndProcedure
		
EndModule
; IDE Options = PureBasic 6.00 Beta 8 (Windows - x64)
; CursorPosition = 12
; Folding = tB+
; EnableXP
; DPIAware