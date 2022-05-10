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
	
	Global Canvas, Width = 800, Height = 600, X = -1, Y = -1
	Global WindowColor, GadgetColor
	
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
; 			Canvas = CanvasGadget(#PB_Any, MainWindow::#Window_Margin, MainWindow::#Window_Margin, WindowWidth(Window) - 2 * MainWindow::#Window_Margin, WindowHeight(Window) - 30 - 2 * MainWindow::#Window_Margin)
			BindEvent(#PB_Event_CloseWindow, @Handler_WindowClose(), Window)
			BindEvent(#PB_Event_SizeWindow, @Handler_WindowSize(), Window)
			WindowColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Parent), 255)
			GadgetColor = SetAlpha(UITK::WindowGetColor(Window, UITK::#Color_Shade_Cold), 255)
			Redraw()
			HideWindow(Window, #False)
		EndIf
	EndProcedure
	
	Procedure Update()
		
	EndProcedure
	
	;Private procedure
	Procedure Handler_WindowSize()
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
EndModule
; IDE Options = PureBasic 6.00 Beta 7 (Windows - x64)
; CursorPosition = 43
; Folding = t--
; EnableXP