IncludeFile "UI-Toolkit/Library/UI-Toolkit.pbi"

IncludePath "Includes"
IncludeFile "General.pbi"
IncludeFile "MainWindow.pbi"
IncludeFile "Tasks.pbi"
IncludeFile "Preview.pbi"

If CountProgramParameters()
	Select ProgramParameter(0)
		Case "-Preview"
			
		Case "-Portable"
			General::Portable = #True
	EndSelect
EndIf

MainWindow::Open()

Repeat
	Select WaitWindowEvent()
		Case #PB_Event_SizeWindow ;Once the windows has been resized, resize the preview image
			If EventWindow() = Preview::Window
				Preview::Resize()
			EndIf
	EndSelect
ForEver


; IDE Options = PureBasic 6.00 Beta 9 (Windows - x64)
; CursorPosition = 7
; EnableXP
; DPIAware