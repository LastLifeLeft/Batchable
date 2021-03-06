IncludeFile "UI-Toolkit/Library/UI-Toolkit.pbi"

IncludePath "Includes"
IncludeFile "General.pbi"
IncludeFile "MainWindow.pbi"
IncludeFile "Tasks.pbi"
IncludeFile "Preview.pbi"
IncludeFile "Worker.pbi"

If CountProgramParameters()
	Select LCase(ProgramParameter(0))
		Case "-worker"
			Worker::Init()
		Case "-portable"
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
; CursorPosition = 13
; EnableXP
; DPIAware