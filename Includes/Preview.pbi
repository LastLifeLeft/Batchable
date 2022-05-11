Module Preview
	
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
	Global WindowColor, GadgetColor
	Global CornerTL, CornerDL, CornerTR, CornerDR
	Global CornerTL_Image = ImageID(CatchImage(#PB_Any, ?_CornerTL)), CornerDL_Image = ImageID(CatchImage(#PB_Any, ?_CornerDL)), CornerTR_Image = ImageID(CatchImage(#PB_Any, ?_CornerTR)), CornerDR_Image = ImageID(CatchImage(#PB_Any, ?_CornerDR))
	
	;Private procedure declaration
	Declare Handler_WindowSize()
	Declare Handler_WindowClose()
	
	Declare Redraw()
	
	;Public procedure
	Procedure Open()
		If Window
			Handler_WindowClose()
		Else
			Window = UITK::Window(#PB_Any, X, Y, Width, Height, General::#AppName + " Preview", UITK::#Window_CloseButton | #PB_Window_SizeGadget | (Bool(X = -1 And Y = -1) * #PB_Window_ScreenCentered) | #PB_Window_Invisible | General::ColorMode)
			UITK::SetWindowBounds(Window, 800, 600, -1, -1)
			WindowColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Parent), 255)
			GadgetColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Shade_Cold), 255)
			
			Container = ContainerGadget(#PB_Any, MainWindow::#Window_Margin, MainWindow::#Window_Margin, WindowWidth(Window) - 2 * MainWindow::#Window_Margin, WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin, #PB_Container_BorderLess)
			SetGadgetColor(Container, #PB_Gadget_BackColor, UITK::WindowGetColor(Window, UITK::#Color_Shade_Cold))
			CornerTL = GadgetID(ImageGadget(#PB_Any, 0, 0, #CornerSize, #CornerSize, CornerTL_Image))
			CornerDL = GadgetID(ImageGadget(#PB_Any, 0, GadgetHeight(Container) - #CornerSize, #CornerSize, #CornerSize, CornerDL_Image))
			CornerTR = GadgetID(ImageGadget(#PB_Any, GadgetWidth(Container) - #CornerSize, 0, #CornerSize, #CornerSize, CornerTR_Image))
			CornerDR = GadgetID(ImageGadget(#PB_Any, GadgetWidth(Container) - #CornerSize, GadgetHeight(Container) - #CornerSize, #CornerSize, #CornerSize, CornerDR_Image))
			
			
; 			Canvas = CanvasGadget(#PB_Any, MainWindow::#Window_Margin, MainWindow::#Window_Margin, WindowWidth(Window) - 2 * MainWindow::#Window_Margin, WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin)
			BindEvent(#PB_Event_CloseWindow, @Handler_WindowClose(), Window)
			BindEvent(#PB_Event_SizeWindow, @Handler_WindowSize(), Window)
			Redraw()
			HideWindow(Window, #False)
		EndIf
		
; 		CreateImage(32, 128, 128, 32, #PB_Image_Transparent)
; 		StartVectorDrawing(ImageVectorOutput(32))
; 		AddPathBox(0, 0, 128, 128)
; 		VectorSourceColor(WindowColor)
; 		FillPath()
; 		UITK::AddPathRoundedBox(0, 0, 128, 128, 5)
; 		VectorSourceColor(GadgetColor)
; 		FillPath()
; 		
; 		StopVectorDrawing()
; 		
; 		UsePNGImageEncoder()
; 		SaveImage(32, "D:\Documents\Border.png", #PB_ImagePlugin_PNG)
	EndProcedure
	
	Procedure Update()
		
	EndProcedure
	
	;Private procedure
	Procedure Handler_WindowSize()
		Protected Height = WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin, Width = WindowWidth(Window) - 2 * MainWindow::#Window_Margin
		ResizeGadget(Container, #PB_Ignore, #PB_Ignore, Width, Height)
		SetWindowPos_(CornerDL, 0, 0, Height - #CornerSize, 0, 0, #SWP_NOZORDER | #SWP_NOACTIVATE | #SWP_NOSIZE)
		SetWindowPos_(CornerTR, 0, Width - #CornerSize, 0, 0, 0, #SWP_NOZORDER | #SWP_NOACTIVATE | #SWP_NOSIZE)
		SetWindowPos_(CornerDR, 0, Width - #CornerSize, Height - #CornerSize, 0, 0, #SWP_NOZORDER | #SWP_NOACTIVATE | #SWP_NOSIZE)
;   		SetWindowPos_(GadgetID(Canvas), 0, 0, 0, WindowWidth(Window) - 2 * MainWindow::#Window_Margin, WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin, #SWP_NOMOVE | #SWP_NOZORDER)
		Redraw()
	EndProcedure
	
	Procedure Handler_WindowClose()
		Width = WindowWidth(Window)
		Height = WindowHeight(Window)
		X = WindowX(Window)
		Y = WindowY(Window)
		
		CloseWindow(Window)
		Window = 0
	EndProcedure
	
	Procedure Redraw()
; 		StartVectorDrawing(CanvasVectorOutput(Canvas))
; 		AddPathBox(0, 0, VectorOutputWidth(), VectorOutputHeight())
; 		VectorSourceColor(WindowColor)
; 		FillPath()
; 		UITK::AddPathRoundedBox(0, 0, VectorOutputWidth(), VectorOutputHeight(), 5)
; 		VectorSourceColor(GadgetColor)
; 		FillPath()
; 		StopVectorDrawing()
	EndProcedure
	
	DataSection
		_CornerTL:
		IncludeBinary "../Media/Corner-TL.png"
		
		_CornerTR:
		IncludeBinary "../Media/Corner-TR.png"
		
		_CornerDL:
		IncludeBinary "../Media/Corner-DL.png"
		
		_CornerDR:
		IncludeBinary "../Media/Corner-DR.png"
	EndDataSection
		
EndModule
; IDE Options = PureBasic 6.00 Beta 7 (Windows - x64)
; CursorPosition = 82
; FirstLine = 12
; Folding = t--
; EnableXP