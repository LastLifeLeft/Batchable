IncludeFile "Libraries/UI-Toolkit.pbi"

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


; IDE Options = PureBasic 6.20 (Windows - x64)
; CursorPosition = 5
; EnableXP
; DPIAware