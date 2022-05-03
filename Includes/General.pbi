DeclareModule General
	#AppName = "Batchable"
	
	; Public procedure declarations
	Declare Min(A, B)
	Declare Max(A, B)
EndDeclareModule

DeclareModule MainWindow
	
	Declare Open()
EndDeclareModule

Module General
	UseJPEG2000ImageDecoder()
	UseJPEGImageDecoder()
	UsePNGImageDecoder()
	UseTGAImageDecoder()
	
	;{ Public procedures
	Procedure Min(A, B)
		If A > B
			ProcedureReturn B
		EndIf
		ProcedureReturn A
	EndProcedure
	
	Procedure Max(A, B)
		If A < B
			ProcedureReturn B
		EndIf
		ProcedureReturn A
	EndProcedure
	;}
	
EndModule
; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 13
; Folding = P-
; EnableXP