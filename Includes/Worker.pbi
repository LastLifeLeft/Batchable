Module Worker
	EnableExplicit
	
	Global Dim Throbber(35)
	Global Window, ImageGadget, TextGadget, Frame, ImageListMutex = CreateMutex(), *Data, ImageCount, TextMutex = CreateMutex()
	#FrameTime = 50
	
	Declare Handler_Timer()
	Declare Handler_Progress()
	Declare ManagerThread(Null)
	
	Procedure Init()
		Protected *Data = AllocateMemory(100000), Size, ID, ImagePath.s, Image
		OpenConsole(General::#AppName)
		
		Delay(10)
		
		While ReadConsoleData(*Data, SizeOf(Ascii))
			ID = PeekA(*Data)
			If ID = 255
				Break
			Else
				AddElement(TaskQueue())
				TaskQueue()\ID = ID
				ReadConsoleData(*Data, SizeOf(Long))
				Size = PeekL(*Data)
				TaskQueue()\Settings = AllocateMemory(Size, #PB_Memory_NoClear)
				ReadConsoleData(TaskQueue()\Settings, Size)
			EndIf
		Wend
		
		While ReadConsoleData(*Data, SizeOf(Long))
			Size = PeekL(*Data)
			Delay(1)
			ReadConsoleData(*Data, Size)
			ImagePath = PeekS(*Data)
			Image = LoadImage(#PB_Any, ImagePath)
			
			If Image
				ForEach TaskQueue()
					Tasks::Task(TaskQueue()\ID)\Execute(Image, TaskQueue()\Settings)
				Next
				
				RenameFile(ImagePath, ImagePath + ".back")
				SaveImage(Image, GetPathPart(ImagePath) + GetFilePart(ImagePath, #PB_FileSystem_NoExtension) + ".png", #PB_ImagePlugin_PNG)
				PokeA(*Data, 1)
			Else
				PokeA(*Data, 0)
			EndIf
			
			WriteConsoleData(*Data, SizeOf(Ascii))
		Wend
		Inkey()
		End
	EndProcedure
	
	Procedure Open()
		Protected Loop, ThreadCount = General::Min(General::Settings_MaxThreadCount, ListSize(ImageList()) - 1), Pointer, SettingSize
		
		DisableWindow(MainWindow::Window, #True)
		If Preview::Window
			DisableWindow(Preview::Window, #True)
		EndIf
		Window = OpenWindow(#PB_Any, 0, 0, 300, 96, "", #PB_Window_BorderLess | #PB_Window_Invisible | #PB_Window_WindowCentered, WindowID(MainWindow::Window))
		SetWindowColor(Window, $3F3936)
		ImageGadget = ImageGadget(#PB_Any, 12, 12, 0, 0, Throbber(Frame))
		TextGadget = TextGadget(#PB_Any, 96, 40, 200, 20, "Batchable is working...", #PB_Text_Center)
		SetGadgetColor(TextGadget, #PB_Gadget_BackColor, $3F3936)
		SetGadgetColor(TextGadget, #PB_Gadget_FrontColor, $FAFAFA)
		ImageCount = ListSize(ImageList())
		TextGadget = TextGadget(#PB_Any, 96, 60, 200, 20, ReplaceString("%!% images left to process.", "%!%", Str(ImageCount)), #PB_Text_Center)
		SetGadgetColor(TextGadget, #PB_Gadget_BackColor, $3F3936)
		SetGadgetColor(TextGadget, #PB_Gadget_FrontColor, $FAFAFA)
		BindEvent(#PB_Event_Timer, @Handler_Timer(), Window)
		AddWindowTimer(Window, 0, #FrameTime)
		
		FirstElement(ImageList())
		
		*Data = AllocateMemory(100000)
		
		ForEach TaskQueue()
			PokeA(*Data + Pointer, TaskQueue()\ID)
			Pointer + SizeOf(Ascii)
			SettingSize = MemorySize(TaskQueue()\Settings)
			PokeL(*Data + Pointer, SettingSize)
			Pointer + SizeOf(Long)
			CopyMemory(TaskQueue()\Settings, *Data + Pointer, SettingSize)
			Pointer + SettingSize
		Next
		
		PokeA(*Data + Pointer, 255)
		Pointer + SizeOf(Ascii)
		
		For Loop = 0 To ThreadCount
			CreateThread(@ManagerThread(), Pointer)
		Next
		
		HideWindow(Window, #False)
	EndProcedure
	
	; Private procedures
	Procedure Handler_Timer()
		Frame = (Frame + 1) % 36
		SetGadgetState(ImageGadget, Throbber(Frame))
	EndProcedure
	
	Procedure Handler_Progress()
		LockMutex(TextMutex)
		ImageCount - 1
		If ImageCount > 0
			SetGadgetText(TextGadget, ReplaceString("%!% images left to process.", "%!%", Str(ImageCount)))
		Else
			CloseWindow(Window)
			FreeMemory(*Data)
			
			DisableWindow(MainWindow::Window, #False)
			If Preview::Window
				DisableWindow(Preview::Window, #False)
			EndIf
		EndIf
		UnlockMutex(TextMutex)
	EndProcedure
	
	Procedure ManagerThread(BufferSize)
		Protected ImagePath.s
		Protected Worker, *CommunicationBuffer = AllocateMemory(2000)
		
		Worker = RunProgram(ProgramFilename(), "-worker", GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Write | #PB_Program_Read | #PB_Program_Hide)
		
		WriteProgramData(Worker, *Data, BufferSize)
		
		Repeat
			LockMutex(ImageListMutex)
			If ListSize(ImageList())
				ImagePath = ImageList()
				DeleteElement(ImageList(), #True)
			Else
				UnlockMutex(ImageListMutex)
				FreeMemory(*CommunicationBuffer)
				CloseProgram(Worker)
				ProcedureReturn #False
			EndIf
			
			UnlockMutex(ImageListMutex)
			
			PokeL(*CommunicationBuffer, StringByteLength(ImagePath))
			PokeS(*CommunicationBuffer + SizeOf(Long), ImagePath)
			WriteProgramData(Worker, *CommunicationBuffer, StringByteLength(ImagePath) + SizeOf(Long))
			
			ReadProgramData(Worker, *CommunicationBuffer, 1)
			
			PostEvent(General::#Process_ItemDone)
		ForEver	
		
	EndProcedure
	
	BindEvent(General::#Process_ItemDone, @Handler_Progress())
	
	;{ Load images
	Throbber(0) = ImageID(CatchImage(#PB_Any, ?Frame0)) ; is this the only solution? Must read about datasection...
	Throbber(1) = ImageID(CatchImage(#PB_Any, ?Frame1))
	Throbber(2) = ImageID(CatchImage(#PB_Any, ?Frame2))
	Throbber(3) = ImageID(CatchImage(#PB_Any, ?Frame3))
	Throbber(4) = ImageID(CatchImage(#PB_Any, ?Frame4))
	Throbber(5) = ImageID(CatchImage(#PB_Any, ?Frame5))
	Throbber(6) = ImageID(CatchImage(#PB_Any, ?Frame6))
	Throbber(7) = ImageID(CatchImage(#PB_Any, ?Frame7))
	Throbber(8) = ImageID(CatchImage(#PB_Any, ?Frame8))
	Throbber(9) = ImageID(CatchImage(#PB_Any, ?Frame9))
	Throbber(10) = ImageID(CatchImage(#PB_Any, ?Frame10))
	Throbber(11) = ImageID(CatchImage(#PB_Any, ?Frame11))
	Throbber(12) = ImageID(CatchImage(#PB_Any, ?Frame12))
	Throbber(13) = ImageID(CatchImage(#PB_Any, ?Frame13))
	Throbber(14) = ImageID(CatchImage(#PB_Any, ?Frame14))
	Throbber(15) = ImageID(CatchImage(#PB_Any, ?Frame15))
	Throbber(16) = ImageID(CatchImage(#PB_Any, ?Frame16))
	Throbber(17) = ImageID(CatchImage(#PB_Any, ?Frame17))
	Throbber(18) = ImageID(CatchImage(#PB_Any, ?Frame18))
	Throbber(19) = ImageID(CatchImage(#PB_Any, ?Frame19))
	Throbber(20) = ImageID(CatchImage(#PB_Any, ?Frame20))
	Throbber(21) = ImageID(CatchImage(#PB_Any, ?Frame21))
	Throbber(22) = ImageID(CatchImage(#PB_Any, ?Frame22))
	Throbber(23) = ImageID(CatchImage(#PB_Any, ?Frame23))
	Throbber(24) = ImageID(CatchImage(#PB_Any, ?Frame24))
	Throbber(25) = ImageID(CatchImage(#PB_Any, ?Frame25))
	Throbber(26) = ImageID(CatchImage(#PB_Any, ?Frame26))
	Throbber(27) = ImageID(CatchImage(#PB_Any, ?Frame27))
	Throbber(28) = ImageID(CatchImage(#PB_Any, ?Frame28))
	Throbber(29) = ImageID(CatchImage(#PB_Any, ?Frame29))
	Throbber(30) = ImageID(CatchImage(#PB_Any, ?Frame30))
	Throbber(31) = ImageID(CatchImage(#PB_Any, ?Frame31))
	Throbber(32) = ImageID(CatchImage(#PB_Any, ?Frame32))
	Throbber(33) = ImageID(CatchImage(#PB_Any, ?Frame33))
	Throbber(34) = ImageID(CatchImage(#PB_Any, ?Frame34))
	Throbber(35) = ImageID(CatchImage(#PB_Any, ?Frame35))
	;}
	
	DataSection ;{
		Frame0:
		IncludeBinary "../Media/Throbber/frame_00.png"
		
		Frame1:
		IncludeBinary "../Media/Throbber/frame_01.png"
		
		Frame2:
		IncludeBinary "../Media/Throbber/frame_02.png"
		
		Frame3:
		IncludeBinary "../Media/Throbber/frame_03.png"
		
		Frame4:
		IncludeBinary "../Media/Throbber/frame_04.png"
		
		Frame5:
		IncludeBinary "../Media/Throbber/frame_05.png"
		
		Frame6:
		IncludeBinary "../Media/Throbber/frame_06.png"
		
		Frame7:
		IncludeBinary "../Media/Throbber/frame_07.png"
		
		Frame8:
		IncludeBinary "../Media/Throbber/frame_08.png"
		
		Frame9:
		IncludeBinary "../Media/Throbber/frame_09.png"
		
		Frame10:
		IncludeBinary "../Media/Throbber/frame_10.png"
		
		Frame11:
		IncludeBinary "../Media/Throbber/frame_11.png"
		
		Frame12:
		IncludeBinary "../Media/Throbber/frame_12.png"
		
		Frame13:
		IncludeBinary "../Media/Throbber/frame_13.png"
		
		Frame14:
		IncludeBinary "../Media/Throbber/frame_14.png"
		
		Frame15:
		IncludeBinary "../Media/Throbber/frame_15.png"
		
		Frame16:
		IncludeBinary "../Media/Throbber/frame_16.png"
		
		Frame17:
		IncludeBinary "../Media/Throbber/frame_17.png"
		
		Frame18:
		IncludeBinary "../Media/Throbber/frame_18.png"
		
		Frame19:
		IncludeBinary "../Media/Throbber/frame_19.png"
		
		Frame20:
		IncludeBinary "../Media/Throbber/frame_20.png"
		
		Frame21:
		IncludeBinary "../Media/Throbber/frame_21.png"
		
		Frame22:
		IncludeBinary "../Media/Throbber/frame_22.png"
		
		Frame23:
		IncludeBinary "../Media/Throbber/frame_23.png"
		
		Frame24:
		IncludeBinary "../Media/Throbber/frame_24.png"
		
		Frame25:
		IncludeBinary "../Media/Throbber/frame_25.png"
		
		Frame26:
		IncludeBinary "../Media/Throbber/frame_26.png"
		
		Frame27:
		IncludeBinary "../Media/Throbber/frame_27.png"
		
		Frame28:
		IncludeBinary "../Media/Throbber/frame_28.png"
		
		Frame29:
		IncludeBinary "../Media/Throbber/frame_29.png"
		
		Frame30:
		IncludeBinary "../Media/Throbber/frame_30.png"
		
		Frame31:
		IncludeBinary "../Media/Throbber/frame_31.png"
		
		Frame32:
		IncludeBinary "../Media/Throbber/frame_32.png"
		
		Frame33:
		IncludeBinary "../Media/Throbber/frame_33.png"
		
		Frame34:
		IncludeBinary "../Media/Throbber/frame_34.png"
		
		Frame35:
		IncludeBinary "../Media/Throbber/frame_35.png"
	EndDataSection ;}
EndModule
; IDE Options = PureBasic 6.00 Beta 9 (Windows - x64)
; CursorPosition = 95
; Folding = V9
; EnableXP