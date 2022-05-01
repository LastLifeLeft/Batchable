Module MainWindow
	EnableExplicit
	; Private variables, structures and constants
	Global Window, ImageList, ButtonAddImage, ButtonAddFolder, ButtonRemoveImage
	
	#MenuBar_Height = 22
	#Window_Margin = 12
	#Window_Height = 700
	#Window_Width = 1200
	#ImageList_Width = 400
	
	; Private procedures declaration
	
	
	;{ Public procedures
	Procedure Open()
		Window = UITK::Window(#PB_Any, 0, 0, #Window_Width - 16, #Window_Height - 9, General::#AppName, UITK::#DarkMode | UITK::#Window_CloseButton | #PB_Window_ScreenCentered)
		UITK::SetWindowIcon(Window, CatchImage(#PB_Any, ?Icon))
		
		ImageList = UITK::VerticalList(#PB_Any, #Window_Margin, #MenuBar_Height + #Window_Margin, #ImageList_Width, #Window_Height - #MenuBar_Height - #Window_Margin * 2, UITK::#VList_Toolbar)
		UITK::SetGadgetProperty(ImageList, UITK::#Properties_CornerRadius, 5)
		EnableGadgetDrop(ImageList, #PB_Drop_Files, #PB_Drag_Move)
		AddGadgetItem(ImageList, -1, "Testouille")
		ButtonAddImage = UITK::Button(#PB_Any, 5, 5, 30, 30, "󱤽")
		SetGadgetFont(ButtonAddImage, 
; 		ButtonAddFolder
; 		ButtonRemoveImage
		
		CloseGadgetList()
	EndProcedure
	;}
	
	;{ Private procedures
	
	;}
	
	DataSection
		Icon:
		IncludeBinary "../Media/Icon/Icon18.png"
	EndDataSection
EndModule
; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 24
; Folding = -
; EnableXP