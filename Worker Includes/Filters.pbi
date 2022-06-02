﻿;All this nice stuff was made by manababel on the french forum: https://www.purebasic.fr/french/viewtopic.php?t=18632
;That's 5000 lines of fast and convenient code, so take a second to thank them if you make some use of it! 

DeclareModule Filter
	
	;Public procedure declarations
	Declare Balance(		SourceImage, Red, Green, Blue, Mask = 0)
	Declare Bend(			SourceImage, Red, Green, Blue, Mask = 0)
	Declare BlackAndWhite(	SourceImage, Red, Green, Blue, Mask = 0)
	Declare BoxBlur(		SourceImage, Horizontal_Scale.q, Vertical_Scale.q, Pass = 1, Seamless = 0, Mask = 0)
	Declare Brightness(		SourceImage, Red, Green, Blue, Mask = 0)
	Declare Color(			SourceImage, Color_option, Color_seuil, Mask = 0) ; Not sure I'm getting it.
	Declare Color_Effect(	SourceImage, color_effect_option, Mask = 0)
	Declare Contrast(		SourceImage, Red, Green, Blue, Mask = 0)
	Declare Emboss(			SourceImage, Emboss_power, Emboss_light, Emboss_opt, Mask = 0)
	Declare Prewitt(		SourceImage, Prewitt_opt = 128, Mask = 0)
	Declare Roberts(		SourceImage, Roberts_opt = 128, Mask = 0)
	Declare Sobel(			SourceImage, Sobel_opt = 128, Mask = 0)
	Declare Tint(			SourceImage, Tint_opt, Mask = 0)
EndDeclareModule

Module Filter
	EnableExplicit
	;Macro
	Macro Emboss_grayscale_macro()
		! PMULLd xmm0, xmm4 ;rgb = (r * $55 + g * $55 + b * $55) ;grayscale
		! pshufd xmm1, xmm0, 1 ;xmm1 = g * $55
		! pshufd xmm2, xmm0, 2 ;xmm2 = r * $55
		! paddd xmm0, xmm1
		! paddd xmm0, xmm2
		! psrad xmm0, 8
		! movd eax, xmm0 
		! mov ecx, 255 ;if eax > 255 : eax = 255 : endif
		! cmp eax, ecx
		! cmovg eax, ecx
		! mov ecx, 0 ;if eax < 0 : eax = 0 : endif
		! cmp eax, ecx
		! cmovl eax, ecx
		! mov ah, al ;eax = eax * $10101
		! shl eax, 8
		! mov al, ah
	EndMacro
	
	Macro Emboss_pos_macro()
		! mov rdx, r8
		! shl rdx, 2
		! add rcx, rdx
		! mov ecx, [rcx]
		! mov rax, [r9 + 24] ;param(3)
		! mul rcx
		! shl rax, 2
		! add rax, [r9 + 00] ;param(0)
	EndMacro
	
	Macro Emboss_pokel_macro()
		! mov rax, [r9 + 24]
		! mov rcx, r8
		! mul rcx
		! shl rax, 2
		! add rax, [r9 + 08]
	EndMacro
	
	
	;Private variables declaration
	Global Dim param(256)
	
	
	;Private procedure declarations
	Declare Balance_thread(i)
	Declare Bend_thread(i)
	Declare BlackAndWhite_thread(i)
	Declare BoxBlur_sp1(i)
	Declare Brightness_thread(i)
	Declare Color_thread(i)
	Declare Color_Effect_thread(i)
	Declare Contrast_mask_thread(i)
	Declare Contrast_thread(i)
	Declare EmbossV1(i)
	Declare EmbossV2(i)
	Declare EmbossV3(i)
	Declare EmbossV4(i)
	Declare EmbossV5(i)
	Declare Prewitt_thread(i)
	Declare Prewitt_mask_thread(i)
	Declare Roberts_thread(i)
	Declare Roberts_mask_thread(i)
	Declare Sobel_thread(i)
	Declare Sobel_mask_thread(i)
	Declare Tint_thread_pb(i) 
	Declare Tint_thread(i) 
	Declare Tint_mask_thread(i) 
	
	
	;Public procedure
	Procedure Balance(SourceImage,Red, Green, Blue, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = ( Red << 32 ) + ( Green << 16 ) + Blue
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				tr(i) = CreateThread(@Balance_thread(), i)
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Bend(SourceImage,Red, Green, Blue, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i, r1.f, g1.f, b1.f
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		Red = Red - 180
		Green = Green - 180
		Blue = Blue - 180
		
		r1 = Red / 255.0 * 3.14 / 180.0
		g1 = Green / 255.0 * 3.14 / 180.0
		b1 = Blue / 255.0 * 3.14 / 180.0
		
		Protected Dim tabr.q(255)
		Protected Dim tabg.q(255)
		Protected Dim tabb.q(255)
		Protected palr = @tabr()
		Protected palg = @tabg()
		Protected palb = @tabb()
		For i = 0 To 255
			tabr(i) = Sin(i * r1) * 127 + i
			tabg(i) = Sin(i * g1) * 127 + i
			tabb(i) = Sin(i * b1) * 127 + i
			If tabr(i) < 0 : tabr(i) = 0 : EndIf
			If tabg(i) < 0 : tabg(i) = 0 : EndIf
			If tabb(i) < 0 : tabb(i) = 0 : EndIf
			If tabr(i) > 255 : tabr(i) = 255 : EndIf
			If tabg(i) > 255 : tabg(i) = 255 : EndIf
			If tabb(i) > 255 : tabb(i) = 255 : EndIf
		Next
		
		param(0) = Psource ;00
		param(1) = Pcible  ;08
		param(2) = Pmask   ;16
		param(3) = lg	   ;24
		param(4) = ht	   ;32
		param(5) = thread  ;40
		param(6) = @tabr() ;48
		param(7) = @tabg() ;56
		param(8) = @tabb() ;64
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				tr(i) = CreateThread(@Bend_thread(), i)
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		FreeArray(tabr())
		FreeArray(tabg())
		FreeArray(tabb())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure BlackAndWhite(SourceImage,Red, Green, Blue, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = ( Red << 16 ) + ( Green << 8 ) + Blue
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				tr(i) = CreateThread(@BlackAndWhite_thread(), i)
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure BoxBlur(SourceImage,Horizontal_Scale.q, Vertical_Scale.q, Pass = 1, Seamless = 0, Mask = 0)
		If Horizontal_Scale = 0 And Vertical_Scale = 0 : ProcedureReturn : EndIf
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		If Pass < 1 : Pass = 1 : EndIf
		
		Protected i, ii, e, nrx, nry, dx, dy, dij, lg, ht, taille, pcible, psource, tempo, thread, s, k
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage)
		taille = lg * ht * 4
		tempo = AllocateMemory(taille)
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		pcible = DrawingBuffer()
		StopDrawing()
		CopyMemory(psource, pcible, taille)
		
		dx = lg - 1
		dy = ht - 1
		If Horizontal_Scale > dx : Horizontal_Scale = dx : EndIf
		If Vertical_Scale > dy : Vertical_Scale = dy : EndIf
		
		nrx = Horizontal_Scale + 1
		nry = Vertical_Scale + 1
		dij = nrx * nry
		
		Protected Dim lx.l(dx + 2 * nrx)
		Protected Dim ly.l(dy + 2 * nry)
		If Seamless
			e = dx - nrx / 2 : For i = 0 To dx + 2 * nrx : lx(i) = (i + e) % (dx + 1) : Next
			e = dy - nry / 2 : For i = 0 To dy + 2 * nry : ly(i) = (i + e) % (dy + 1) : Next
		Else 
			For i = 0 To dx + 2 * nrx : ii = i - 1 - nrx / 2 : If ii < 0 : ii = 0 : EndIf : If ii > dx : ii = dx : EndIf : lx(i) = ii : Next
			For i = 0 To dy + 2 * nry : ii = i - 1 - nry / 2 : If ii < 0 : ii = 0 : ElseIf ii > dy : ii = dy : EndIf : ly(i) = ii : Next
		EndIf 
		
		param(0) = psource
		param(1) = pcible
		param(2) = tempo
		param(3) = lg
		param(4) = ht
		param(5) = nrx
		param(6) = nry
		param(7) = lx()
		param(8) = ly()
		param(9) = thread
		param(10) = dij
		
		For k = 1 To Pass
			For i = 0 To thread - 1 : tr(i) = 0 : Next
			For i = 0 To thread - 1 : While tr(i) = 0 : tr(i) = CreateThread(@BoxBlur_sp1(), i) : Wend : Next
			For i = 0 To thread - 1 : If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf : Next
			CopyMemory(tempo, pcible, taille)
		Next
		
		CopyMemory(tempo, pcible, taille)
		
		If Mask < > 0
			Protected Dim Reg_memory.q(5 * 8)
			
			StartDrawing(ImageOutput(Mask))
			Protected pmask = DrawingBuffer()
			lg = ImageWidth(SourceImage)
			ht = ImageHeight(SourceImage)
			Protected taillex = lg * ht
			StopDrawing()
			
			s = @reg_memory() ;calcul du mask
			! mov rax, [p.v_s]
			! mov [rax + 000], r10
			! mov [rax + 008], r11
			! mov [rax + 016], r12
			! mov [rax + 024], rcx
			
			! mov rcx, [p.v_pmask]
			! mov r8, [p.v_psource]
			! mov r9, [p.v_pcible]
			! xor rdx, rdx
			! Filter_guillossien_mask_saut01 : 
			! mov r10d, [rcx + rdx * 4];, [p.v_Pmask]
			! mov r11d, [r8 + rdx * 4];r8, [p.v_Psource]
			! mov r12d, [r9 + rdx * 4];, [p.v_Pcible]
			
			! and r12d, r10d
			! xor r10d, $ffffffff
			! and r11d, r10d
			! or r11d, r12d
			! mov [r9 + rdx * 4], r11d
			
			! inc rdx
			! cmp rdx, [p.v_taillex]
			! jb Filter_guillossien_mask_saut01
			
			! mov rax, [p.v_s]
			! mov r10, [rax + 000]
			! mov r11, [rax + 008]
			! mov r12, [rax + 016]
			! mov rcx, [rax + 024]
			
			FreeArray(Reg_memory())
			
		EndIf
		
		FreeMemory(tempo)
		FreeArray(tr())
		FreeArray(lx())
		FreeArray(ly())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Brightness(SourceImage,Red, Green, Blue, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		Red = Red - 255
		Green = Green - 255
		Blue = Blue - 255
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = Red << 32 + Green << 16 + Blue
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				tr(i) = CreateThread(@Brightness_thread(), i)
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Color(SourceImage,Color_option, Color_seuil, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		If Color_option < 0 : Color_option = 0 : EndIf
		If Color_option > 11 : Color_option = 11 : EndIf
		If Color_seuil < 0 : Color_seuil = 0 : EndIf
		If Color_seuil > 255 : Color_seuil = 255 : EndIf
		
		Protected thread, Psource, Pcible, Pmask, lg, ht, opt, i
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = Color_option
		param(7) = Color_seuil
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				tr(i) = CreateThread(@Color_thread(), i)
			Wend
		Next
		
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Color_Effect(SourceImage,color_effect_option, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		If color_effect_option < 0 : color_effect_option = 0 : EndIf
		If color_effect_option > 4 : color_effect_option = 4 : EndIf
		Protected thread, Psource, Pcible, Pmask, lg, ht, opt, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = color_effect_option
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		
		For i = 0 To thread - 1
			While tr(i) = 0 
				tr(i) = CreateThread(@color_effect_thread(), i)
			Wend
		Next
		
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Contrast(SourceImage,Red, Green, Blue, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i ;
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource ;00
		param(1) = Pcible  ;08
		param(2) = Pmask   ;16
		param(3) = lg	   ;24
		param(4) = ht	   ;32
		param(5) = thread  ;40
		param(6) = Red - 256
		param(7) = Green - 256
		param(8) = Blue - 256
		
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				If Mask = 0
					tr(i) = CreateThread(@Contrast_thread(), i)
				Else
					tr(i) = CreateThread(@Contrast_mask_thread(), i)
				EndIf 
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Emboss(SourceImage,Emboss_power, Emboss_light, Emboss_opt, Mask = 0)
		If SourceImage = 0: ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i, nx1, ny1, nx2, ny2, nx3, ny3, nx4, ny4, nx5, ny5, nx6, ny6, px1, px2, px3, px4, px5, px6, py1, py2, py3, py4, py5, py6, s, taille
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		Protected Dim tx1.l(lg + 3)
		Protected Dim ty1.l(ht + 3)
		Protected Dim tx2.l(lg + 3)
		Protected Dim ty2.l(ht + 3)
		Protected Dim tx3.l(lg + 3)
		Protected Dim ty3.l(ht + 3)
		Protected Dim tx4.l(lg + 3)
		Protected Dim ty4.l(ht + 3)
		Protected Dim tx5.l(lg + 3)
		Protected Dim ty5.l(ht + 3)
		Protected Dim tx6.l(lg + 3)
		Protected Dim ty6.l(ht + 3)
		
		;coordonnees de chaque pixel pour le precalcul de position
		Select Emboss_opt
			Case 0, 16
				nx1 = - 1 : ny1 = - 1 : nx2 = 0 : ny2 = 0 : nx3 = 1 : ny3 = 1
			Case 1, 17
				nx1 = - 1 : ny1 = - 0 : nx2 = 0 : ny2 = 0 : nx3 = 1 : ny3 = 0
			Case 2, 18
				nx1 = - 1 : ny1 = 1 : nx2 = 0 : ny2 = 0 : nx3 = 1 : ny3 = - 1
			Case 3, 19
				nx1 = 0 : ny1 = 1 : nx2 = 0 : ny2 = 0 : nx3 = 0 : ny3 = - 1
			Case 4, 20
				nx1 = 1 : ny1 = 1 : nx2 = 0 : ny2 = 0 : nx3 = - 1 : ny3 = - 1
			Case 5, 21
				nx1 = 1 : ny1 = 0 : nx2 = 0 : ny2 = 0 : nx3 = - 1 : ny3 = 0
			Case 6, 22
				nx1 = 1 : ny1 = - 1 : nx2 = 0 : ny2 = 0 : nx3 = - 1 : ny3 = 1
			Case 7, 23
				nx1 = 0 : ny1 = - 1 : nx2 = 0 : ny2 = 0 : nx3 = 0 : ny3 = 1
			Case 8
				nx1 = - 1 : ny1 = - 1 : nx2 = 1 : ny2 = 1
			Case 9
				nx1 = - 1 : ny1 = - 0 : nx2 = 1 : ny2 = 0
			Case 10
				nx1 = - 1 : ny1 = 1 : nx2 = 1 : ny2 = - 1
			Case 11
				nx1 = 0 : ny1 = 1 : nx2 = 0 : ny2 = - 1
			Case 12
				nx1 = 1 : ny1 = 1 : nx2 = - 1 : ny2 = - 1
			Case 13
				nx1 = 1 : ny1 = 0 : nx2 = - 1 : ny2 = 0
			Case 14
				nx1 = 1 : ny1 = - 1 : nx2 = - 1 : ny2 = 1
			Case 15
				nx1 = 0 : ny1 = - 1 : nx2 = 0 : ny2 = 1
			Case 24
				nx1 = 0 : ny1 = - 1 : nx2 = - 1 : ny2 = - 1 : nx3 = - 1 : ny3 = 0
			Case 25
				nx1 = - 1 : ny1 = 0 : nx2 = - 1 : ny2 = 1 : nx3 = 0 : ny3 = 1
			Case 26
				nx1 = 0 : ny1 = 1 : nx2 = 1 : ny2 = 1 : nx3 = 1 : ny3 = 0
			Case 27
				nx1 = 1 : ny1 = 0 : nx2 = 1 : ny2 = - 1 : nx3 = 0 : ny3 = - 1
			Case 28
				nx1 = - 1 : ny1 = 0 : nx2 = 0 : ny2 = 1 : nx3 = 1 : ny3 = 0 : nx4 = 0 : ny4 = - 1
			Case 29
				nx1 = - 1 : ny1 = 1 : nx2 = 1 : ny2 = 1 : nx3 = 1 : ny3 = - 1 : nx4 = - 1 : ny4 = - 1
			Case 30
				nx1 = - 1 : ny1 = - 1 : nx2 = 0 : ny2 = - 1 : nx3 = - 1 : ny3 = 0 : nx4 = 1 : ny4 = 1 : nx5 = 0 : ny5 = 1 : nx6 = 1 : ny6 = 0
			Case 31
				nx1 = - 1 : ny1 = 1 : nx2 = 0 : ny2 = 1 : nx3 = - 1 : ny3 = 0 : nx4 = 1 : ny4 = - 1 : nx5 = 0 : ny5 = - 1 : nx6 = 1 : ny6 = 0
			Case 32
				nx1 = 1 : ny1 = 1 : nx2 = 0 : ny2 = 1 : nx3 = 1 : ny3 = 0 : nx4 = - 1 : ny4 = - 1 : nx5 = 0 : ny5 = - 1 : nx6 = - 1 : ny6 = 0
			Case 33
				nx1 = 1 : ny1 = - 1 : nx2 = 0 : ny2 = - 1 : nx3 = 1 : ny3 = 0 : nx4 = - 1 : ny4 = 1 : nx5 = 0 : ny5 = 1 : nx6 = - 1 : ny6 = 0
			Case 34
				nx1 = - 1 : ny1 = - 1 : nx2 = 0 : ny2 = 0 : nx3 = 1 : ny3 = 1
		EndSelect
		
		;precalcul des pixel en "x" et en "y"
		;permet supprimer les tests de depassement de chaque pixel hors "ecran"
		For i = 0 To lg - 1 
			px1 = i + nx1 : If px1 < 0 : px1 = 0 : EndIf : If px1 > ( lg - 1 ) : px1 = lg - 1 : EndIf : tx1(i) = px1 * 4
			px2 = i + nx2 : If px2 < 0 : px2 = 0 : EndIf : If px2 > ( lg - 1 ) : px2 = lg - 1 : EndIf : tx2(i) = px2 * 4
			px3 = i + nx3 : If px3 < 0 : px3 = 0 : EndIf : If px3 > ( lg - 1 ) : px3 = lg - 1 : EndIf : tx3(i) = px3 * 4
			px4 = i + nx4 : If px4 < 0 : px4 = 0 : EndIf : If px4 > ( lg - 1 ) : px4 = lg - 1 : EndIf : tx4(i) = px4 * 4
			px5 = i + nx5 : If px5 < 0 : px5 = 0 : EndIf : If px5 > ( lg - 1 ) : px5 = lg - 1 : EndIf : tx5(i) = px5 * 4
			px6 = i + nx6 : If px6 < 0 : px6 = 0 : EndIf : If px6 > ( lg - 1 ) : px6 = lg - 1 : EndIf : tx6(i) = px6 * 4
		Next
		
		For i = 0 To ht + 1
			py1 = i + ny1 : If py1 < 0 : py1 = 0 : EndIf : If py1 > ( ht - 1 ) : py1 = ht - 1 : EndIf : ty1(i) = py1
			py2 = i + ny2 : If py2 < 0 : py2 = 0 : EndIf : If py2 > ( ht - 1 ) : py2 = ht - 1 : EndIf : ty2(i) = py2
			py3 = i + ny3 : If py3 < 0 : py3 = 0 : EndIf : If py3 > ( ht - 1 ) : py3 = ht - 1 : EndIf : ty3(i) = py3
			py4 = i + ny4 : If py4 < 0 : py4 = 0 : EndIf : If py4 > ( ht - 1 ) : py4 = ht - 1 : EndIf : ty4(i) = py4
			py5 = i + ny5 : If py5 < 0 : py5 = 0 : EndIf : If py5 > ( ht - 1 ) : py5 = ht - 1 : EndIf : ty5(i) = py4
			py6 = i + ny6 : If py6 < 0 : py6 = 0 : EndIf : If py6 > ( ht - 1 ) : py6 = ht - 1 : EndIf : ty6(i) = py4
		Next 
		
		param(0) = Psource;00
		param(1) = Pcible ;08
		param(2) = Pmask  ;16 
		param(3) = lg	  ;24
		param(4) = ht	  ;32
		param(5) = thread ;40
		param(6) = Emboss_power ;48
		param(7) = Emboss_light	;56
		param(8) = @tx1()		;64
		param(9) = @ty1()		;72
		param(10) = @tx2()		;80
		param(11) = @ty2()		;88
		param(12) = @tx3()		;96
		param(13) = @ty3()		;104
		param(14) = @tx4()		;112
		param(15) = @ty4()		;120
		param(16) = @tx5()		;128
		param(17) = @ty5()		;136
		param(18) = @tx6()		;144
		param(19) = @ty6()		;152
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		
		Select Emboss_opt
			Case 0 To 15
				For i = 0 To thread - 1
					While tr(i) = 0 
						tr(i) = CreateThread(@EmbossV1(), i)
					Wend
				Next
			Case 16 To 27
				For i = 0 To thread - 1
					While tr(i) = 0 
						tr(i) = CreateThread(@EmbossV2(), i)
					Wend
				Next
			Case 28, 29
				For i = 0 To thread - 1
					While tr(i) = 0 
						tr(i) = CreateThread(@EmbossV3(), i)
					Wend
				Next
			Case 30 To 33
				For i = 0 To thread - 1
					While tr(i) = 0 
						tr(i) = CreateThread(@EmbossV4(), i)
					Wend
				Next
			Case 34
				For i = 0 To thread - 1
					While tr(i) = 0 
						tr(i) = CreateThread(@EmbossV5(), i)
					Wend
				Next 
		EndSelect
		
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		
		FreeArray(tr())
		
		Protected Dim Reg_memory.q(3 * 8)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! mov [rax + 000], r10
		! mov [rax + 008], r11
		! mov [rax + 016], r12
		
		If Mask < > 0
			
			taille = lg * ht
			! mov rcx, [p.v_Pmask]
			! mov r8, [p.v_Psource]
			! mov r9, [p.v_Pcible]
			! xor rdx, rdx
			! saut01 : 
			! mov r10d, [rcx + rdx * 4];, [p.v_Pmask]
			! mov r11d, [r8 + rdx * 4];r8, [p.v_Psource]
			! mov r12d, [r9 + rdx * 4];, [p.v_Pcible]
			
			! and r12d, r10d
			! xor r10d, $ffffffff
			! and r11d, r10d
			! or r11d, r12d
			! mov [r9 + rdx * 4], r11d
			
			! inc rdx
			! cmp rdx, [p.v_taille]
			! jb saut01
			
			! mov rax, [p.v_s]
			! mov r10, [rax + 000]
			! mov r11, [rax + 008]
			! mov r12, [rax + 016]
			
			FreeArray(Reg_memory())
			
		EndIf
		
		FreeArray(tx1())
		FreeArray(ty1())
		FreeArray(tx2())
		FreeArray(ty2())
		FreeArray(tx3())
		FreeArray(ty3())
		FreeArray(tx4())
		FreeArray(ty4())
		FreeArray(tx5())
		FreeArray(ty5())
		FreeArray(tx6())
		FreeArray(ty6())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Prewitt(SourceImage,Prewitt_opt = 128, Mask = 0)
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = Prewitt_opt
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				If Mask = 0
					tr(i) = CreateThread(@Prewitt_thread(), i)
				Else
					tr(i) = CreateThread(@Prewitt_mask_thread(), i)
				EndIf
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Roberts(SourceImage,Roberts_opt = 128, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = Roberts_opt
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				If Mask = 0
					tr(i) = CreateThread(@Roberts_thread(), i)
				Else
					tr(i) = CreateThread(@Roberts_mask_thread(), i)
				EndIf
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Sobel(SourceImage,Sobel_opt = 128, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = Sobel_opt
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				If Mask = 0
					tr(i) = CreateThread(@Sobel_thread(), i)
				Else
					tr(i) = CreateThread(@Sobel_mask_thread(), i)
				EndIf
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	Procedure Tint(SourceImage,Tint_opt, Mask = 0)
		
		If SourceImage = 0 : ProcedureReturn : EndIf
		Protected Temp = SourceImage, OutputImage
		SourceImage = CopyImage(SourceImage, #PB_Any)
		OutputImage = Temp
		Protected thread, Psource, Pcible, Pmask, lg, ht, i
		
		thread = CountCPUs(#PB_System_CPUs)
		If thread < 2 : thread = 1 : EndIf
		
		Protected Dim tr.q(thread)
		
		StartDrawing(ImageOutput(SourceImage))
		Psource = DrawingBuffer()
		lg = ImageWidth(SourceImage)
		ht = ImageHeight(SourceImage) 
		StopDrawing()
		
		StartDrawing(ImageOutput(OutputImage))
		Pcible = DrawingBuffer()
		StopDrawing()
		
		If Mask < > 0
			StartDrawing(ImageOutput(Mask))
			Pmask = DrawingBuffer()
			StopDrawing()
		EndIf
		
		param(0) = Psource
		param(1) = Pcible
		param(2) = Pmask
		param(3) = lg
		param(4) = ht
		param(5) = thread
		param(6) = Tint_opt
		
		For i = 0 To thread - 1 : tr(i) = 0 : Next
		For i = 0 To thread - 1
			While tr(i) = 0 
				If Mask = 0
					tr(i) = CreateThread(@Tint_thread(), i)
				Else
					tr(i) = CreateThread(@Tint_mask_thread(), i)
				EndIf
			Wend
		Next
		For i = 0 To thread - 1
			If IsThread(tr(i)) > 0 : WaitThread(tr(i)) : EndIf 
		Next
		
		FreeArray(tr())
		
		FreeImage(SourceImage)
	EndProcedure
	
	
	;Private procedure
	Procedure Balance_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		Protected Dim Reg_memory.q(6 * 8 + 4 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rcx
		! mov [rax + 008], rdx
		! mov [rax + 016], r8
		! mov [rax + 024], r9
		! mov [rax + 032], r10
		! mov [rax + 040], r11
		! movdqu [rax + 048], xmm0
		! movdqu [rax + 064], xmm1
		! movdqu [rax + 080], xmm2
		! movdqu [rax + 096], xmm3
		
		! mov rax, [p.v_p]
		! mov rcx, [rax + 16]
		! cmp rcx, 0
		! jnz Filter_Balance_mask_thread_saut
		;programme sans le mask
		! mov rcx, [rax + 08] ;cible
		! mov rdx, [p.v_start]
		! pxor xmm0, xmm0
		! movq xmm1, [rax + 48] ;opt
		! punpcklwd xmm1, xmm0 ;coversion 16bits - > 32bits
		! mov rax, [rax + 00] ;source
		! boucle_Filter_Balance_thread_01 : 
		! movd xmm2, [rax + rdx * 4]
		! punpcklbw xmm2, xmm0 ;coversion 8bits - > 16bits (4X8 bits) - > (4X32 bits)
		! punpcklwd xmm2, xmm0 ;coversion 16bits - > 32bits
		! pmulld xmm2, xmm1
		! psrld xmm2, 8 ;>> 8
		! packusdw xmm2, xmm0 ;coversion 32bits - > 16bits
		! packuswb xmm2, xmm0 ;coversion 16bits - > 8bits
		! movd [rcx + rdx * 4], xmm2
		! add rdx, 1
		! cmp rdx, [p.v_stop]
		! jb boucle_Filter_Balance_thread_01 
		! jp Filter_Balance_mask_thread_end 
		
		;programme avec le mask
		! Filter_Balance_mask_thread_saut : 
		! mov rax, [p.v_p]
		! mov r8, [rax + 16] ;mask
		! mov rcx, [rax + 08] ;cible
		! mov rdx, [p.v_start]
		! pxor xmm0, xmm0
		! movq xmm1, [rax + 48] ;opt
		! punpcklwd xmm1, xmm0
		! mov rax, [rax + 00] ;source
		! boucle_Filter_Balance_mask_thread_01 : 
		! mov r10d, [rax + rdx * 4]
		! movd xmm2, [rax + rdx * 4]
		! punpcklbw xmm2, xmm0
		! punpcklwd xmm2, xmm0
		! pmulld xmm2, xmm1
		! psrld xmm2, 8
		! packusdw xmm2, xmm0
		! packuswb xmm2, xmm0
		! movd r9d, xmm2
		! mov r11d, [r8 + rdx * 4]
		! and r9d, r11d
		! xor r11d, $ffffffff
		! and r10d, r11d
		! or r10d, r9d
		! mov [rcx + rdx * 4], r10d
		! add rdx, 1
		! cmp rdx, [p.v_stop]
		! jb boucle_Filter_Balance_mask_thread_01 
		
		! Filter_Balance_mask_thread_end : 
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rcx, [rax + 000]
		! mov rdx, [rax + 008]
		! mov r8, [rax + 016]
		! mov r9, [rax + 024]
		! mov r10, [rax + 032]
		! mov r11, [rax + 040]
		! movdqu xmm0, [rax + 048]
		! movdqu xmm1, [rax + 064]
		! movdqu xmm2, [rax + 080]
		! movdqu xmm3, [rax + 096]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Bend_thread(i)
		Protected start, stop, p, s
		p = @param()
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		Protected Dim Reg_memory.q(10 * 8) ;(10 registes 64bits)
		s = @reg_memory()				   ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 056], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		
		! mov rax, [p.v_p] 
		! mov rsi, [rax + 00] ;source
		! mov rdi, [rax + 08] ;cible
		! mov r11, [rax + 16] ;mask
		! mov r8, [rax + 48] ;palr
		! mov r9, [rax + 56] ;palg
		! mov r10, [rax + 64] ;palb
		! mov rdx, [p.v_start]
		! shl rdx, 2
		! add rsi, rdx ;source = source + start
		! add rdi, rdx ;cible = cible + start
		! shr rdx, 2
		! cmp r11, 0
		! jnz Bend_mask_thread_saut
		
		! Boucle_Bend : 
		! xor rax, rax
		! xor rbx, rbx
		! mov bl, [rsi + 2]
		! mov al, [r8 + rbx * 8]
		! shl rax, 8
		! mov bl, [rsi + 1]
		! mov al, [r9 + rbx * 8]
		! shl rax, 8
		! mov bl, [rsi + 0]
		! mov al, [r10 + rbx * 8]
		! mov [rdi], eax
		! add rsi, 4
		! add rdi, 4 
		! inc rdx
		! cmp rdx, [p.v_stop]
		! jb Boucle_Bend 
		! jp Bend_mask_thread_end
		
		! Bend_mask_thread_saut : 
		! Boucle_Bend_mask : 
		! xor rax, rax
		! xor rbx, rbx
		! mov bl, [rsi + 2]
		! mov al, [r8 + rbx * 8]
		! shl rax, 8
		! mov bl, [rsi + 1]
		! mov al, [r9 + rbx * 8]
		! shl rax, 8
		! mov bl, [rsi + 0]
		! mov al, [r10 + rbx * 8]
		
		! mov ebx, [rsi] 
		! mov r12d, [r11 + rdx * 4]
		! and eax, r12d
		! xor r12d, $ffffffff
		! and ebx, r12d 
		! or ebx, eax 
		! mov [rdi], ebx 
		
		! add rsi, 4
		! add rdi, 4 
		! inc rdx
		! cmp rdx, [p.v_stop]
		! jb Boucle_Bend_mask 
		
		! Bend_mask_thread_end : 
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		FreeArray(Reg_memory())
	EndProcedure
	
	Procedure BlackAndWhite_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		Protected Dim Reg_memory.q(7 * 8 + 4 * 16 ) ;(7 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], r8
		! mov [rax + 008], r9
		! mov [rax + 016], r10
		! mov [rax + 024], r11
		! mov [rax + 032], r12
		! mov [rax + 040], r13
		! mov [rax + 048], rdx
		! movdqu [rax + 056], xmm0
		! movdqu [rax + 072], xmm1
		! movdqu [rax + 088], xmm2
		! movdqu [rax + 104], xmm3
		
		
		! mov rax, [p.v_p]
		! mov r8, [rax + 00] ;source
		! mov r9, [rax + 08] ;cible
		! mov r10, [rax + 16] ;mask
		! movd xmm1, [rax + 48] ;opt
		! mov edx, $00808080
		! movd xmm0, edx
		! psubb xmm1, xmm0
		! mov eax, $007f7f7f
		! movd xmm3, eax 
		! mov rdx, [p.v_start] 
		
		! cmp r10, 0
		! jnz BlackAndWhite_mask_saut
		
		! BlackAndWhite_thread : 
		! movd xmm0, [r8 + rdx * 4] 
		! psubb xmm0, xmm3 ;soustraction pour passer de (0 à 255) - > ( - 127 à 128)
		! pcmpgtb xmm0, xmm1 ;compare des valeurs entre - 127 et 128 ( if xmm0 > xmm 1 ) return 255 else return 0 
		! movd [r9 + rdx * 4], xmm0 
		! inc rdx 
		! cmp rdx, [p.v_stop]
		! jb BlackAndWhite_thread 
		! jp BlackAndWhite_mask_end
		
		! BlackAndWhite_mask_saut : 
		
		! BlackAndWhite_mask_thread : 
		! mov r13d, [r8 + rdx * 4]
		! movd xmm0, r13d 
		! psubb xmm0, xmm3 ;soustraction pour passer de (0 à 255) - > ( - 127 à 128)
		! pcmpgtb xmm0, xmm1 ;compare des valeurs entre - 127 et 128 ( if xmm0 > xmm 1 ) return 255 else return 0 
		
		! movd r12d, xmm0
		! mov r11d, [r10 + rdx * 4]
		! and r12d, r11d
		! xor r11d, $ffffffff
		! and r13d, r11d
		! or r13d, r12d
		
		! mov [r9 + rdx * 4], r13d 
		! inc rdx 
		! cmp rdx, [p.v_stop]
		! jb BlackAndWhite_mask_thread 
		
		! BlackAndWhite_mask_end : 
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov r8, [rax + 000]
		! mov r9, [rax + 008]
		! mov r10, [rax + 016]
		! mov r11, [rax + 024]
		! mov r12, [rax + 032]
		! mov r13, [rax + 040]
		! mov rdx, [rax + 048]
		! movdqu xmm0, [rax + 056]
		! movdqu xmm1, [rax + 072]
		! movdqu xmm2, [rax + 088]
		! movdqu xmm3, [rax + 104]
		FreeArray(Reg_memory())
	EndProcedure
	
	Procedure BoxBlur_sp1(i)
		
		Protected p, d.f, start, stop, y, pos, ht
		p = @param()
		
		d = 1 / param(10) ;dx
		start = ( param(4) / param(9) ) * i
		stop = ( param(4) / param(9) ) * (i + 1) - 1
		If i = (param(9) - 1) ;ndt
			If stop < ht : stop = param(4) - 1 : EndIf ;ht is always 0
		EndIf 
		
		;d.f = 1 / dx
		! mov r9, [p.v_p]
		! mov r8, [r9 + 56];[p.v_tx]
		! pxor xmm3, xmm3
		For y = start To stop
			pos = param(1) + ( param(3) * y << 2 )
			
			! pxor xmm1, xmm1
			! pxor xmm2, xmm2
			For i = - param(5) To param(5)
				! mov rax, [p.v_i] ;var = PeekL( tab_tx + (i + rx) * 4 )
				! add rax, [r9 + 40];[p.v_rx] ;(i + rx)
				! mov eax, [r8 + rax * 4] ;var = PeekL(pos + var * 4)
				! add rax, [p.v_pos] ;r14 = (pos + var * 4)
				! movd xmm0, [rax] ;peekl(pos + var * 4) 
				! punpcklbw xmm0, xmm3
				! punpcklwd xmm0, xmm3
				! paddd xmm2, xmm0
			Next
			
			! mov rcx, [p.v_y]
			! mov rax, [r9 + 24];[p.v_lg]
			! mul rcx
			! shl rax, 2
			! add rax, [r9 + 16];[p.v_tempo]
			! mov rcx, rax
			
			! xor rdx, rdx
			! BoxBlur_bouclex : ;For x = 0 To (lg - 1)
			! mov eax, [r8 + rdx * 4] ;tx(x)
			! add rax, [p.v_pos] ;pos + var * 4
			! movd xmm0, [rax] ;PeekL(pos + var << 4)
			! punpcklbw xmm0, xmm3
			! punpcklwd xmm0, xmm3
			
			! mov rax, rdx ;[p.v_x]
			! add rax, [r9 + 80];[p.v_dx] ;(x + dx ) 
			! mov eax, [r8 + rax * 4] ;PeekL(tab_tx + (x + dx) * 4 ) 
			! add rax, [p.v_pos]
			! movd xmm1, [rax] ;(pos + var * 4)
			! punpcklbw xmm1, xmm3
			! punpcklwd xmm1, xmm3
			
			! psubd xmm2, xmm0
			! paddd xmm2, xmm1
			
			! movdqu xmm0, xmm2
			! cvtdq2ps xmm0, xmm0
			! movd xmm1, [p.v_d]
			! pshufd xmm1, xmm1, 0
			! mulps xmm0, xmm1
			! cvtps2dq xmm0, xmm0
			! packusdw xmm0, xmm3
			! packuswb xmm0, xmm3
			
			! movd [rcx], xmm0
			! add rcx, 4
			
			! inc rdx
			! cmp rdx, [r9 + 24];[p.v_lg]
			! jb BoxBlur_bouclex ;Next 
			
		Next 
		
	EndProcedure
	
	Procedure Brightness_thread(i)
		
		Protected tt, start, stop, p, s
		p = @param()
		
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		Protected Dim Reg_memory.q(3 * 8)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! mov [rax + 000], r15
		! mov [rax + 008], r14
		! mov [rax + 016], r13
		
		! mov rax, [p.v_p]
		! mov rcx, [rax + 00] ;source
		! mov rdx, [rax + 08] ;cible
		! mov r15, [rax + 16] ;mask
		! movq xmm0, [rax + 48] ;opt
		! pxor xmm3, xmm3
		! mov rax, [p.v_start]
		
		! cmp r15, 0
		! jnz Brightness_thread_saut
		
		! Brightness_thread_1 : 
		! movd xmm1, [rcx + rax * 4] 
		! punpcklbw xmm1, xmm3 
		! paddsw xmm1, xmm0 
		! packuswb xmm1, xmm1 
		! movd [rdx + rax * 4], xmm1 
		! inc rax
		! cmp rax, [p.v_stop]
		! jb Brightness_thread_1 
		! jp Brightness_thread_end
		
		! Brightness_thread_saut : 
		
		! Brightness_mask_thread_1 : 
		! mov r8d, [rcx + rax * 4] 
		! movd xmm1, r8d
		! punpcklbw xmm1, xmm3 
		! paddsw xmm1, xmm0 
		! packuswb xmm1, xmm1 
		
		! movd r13d, xmm1 ;calcul du mask
		! mov r14d, [r15 + rax * 4]
		! and r13d, r14d ;modification dans le mask
		! xor r14d, $ffffffff
		! and r8d, r14d
		! or r8d, r13d ;ajout de la partie hors du mask
		
		! mov [rdx + rax * 4], r8d 
		! inc rax
		! cmp rax, [p.v_stop]
		! jb Brightness_mask_thread_1 
		
		! Brightness_thread_end : 
		
		! mov rax, [p.v_s]
		! mov r15, [rax + 000]
		! mov r14, [rax + 008]
		! mov r13, [rax + 016]
		
	EndProcedure
	
	Procedure Color_thread(i)
		
		Protected start, stop, p, s 
		p = @param()
		
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		
		Protected Dim Reg_memory.q(5 * 8)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! mov [rax + 000], r10
		! mov [rax + 008], r11
		! mov [rax + 016], r12
		! mov [rax + 024], r13
		! mov [rax + 032], r15
		
		Select param(6)
				;- - red < (or)
			Case 0 ;If (r < g) Or (r < b) Or (r < seuil) then (((r + g + b) * 21845) >> 16) * $10101
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_00 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 02] ;r
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! jb saut_Color_00_ok
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! jb saut_Color_00_ok
				! cmp al, byte [r15 + 56] ;seuil
				! ja saut_Color_00_end
				! saut_Color_00_ok : 
				
				! mov rax, 21845 ;gray
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_00_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_00_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_00
				
			Case 1 ;If (g < r) Or (g < b) Or (r < seuil) then (((r + g + b) * 21845) >> 16) * $10101
				   ;- - green < (or)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_01 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 01] ;g
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! jb saut_Color_01_ok
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! jb saut_Color_01_ok
				! cmp al, byte [r15 + 56] ;seuil
				! ja saut_Color_01_end
				! saut_Color_01_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_01_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_01_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_01
				
			Case 2 ;If (b < g) Or (b < r) Or (b > seuil)
				   ;- - blue < (or)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_02 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 00] ;b
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! jb saut_Color_02_ok
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! jb saut_Color_02_ok
				! cmp al, byte [r15 + 56] ;seuil
				! ja saut_Color_02_end
				! saut_Color_02_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_02_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_02_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_02
				;- - 
				;- - red > (or)
			Case 3 ;If (r > g) Or (r > b) Or (r > seuil)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_03 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 02] ;r
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! ja saut_Color_03_ok
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! ja saut_Color_03_ok
				! cmp al, byte [r15 + 56] ;seuil
				! ja saut_Color_03_end
				! saut_Color_03_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_03_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_03_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_03
				
				;- - green > (or) 
			Case 4 ;If (g > r) Or (g > b) Or (g > seuil)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_04 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 01] ;g
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! ja saut_Color_04_ok
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! ja saut_Color_04_ok
				! cmp al, byte [r15 + 56] ;seuil
				! ja saut_Color_04_end
				! saut_Color_04_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_04_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_04_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_04
				
				;- - blue > (or) 
			Case 5 ;If (b > r) Or (b > g) Or (g > seuil)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_05 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 00] ;b
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! ja saut_Color_05_ok
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! ja saut_Color_05_ok
				! cmp al, byte [r15 + 56] ;seuil
				! ja saut_Color_05_end
				! saut_Color_05_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_05_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_05_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_05
				
				;- - 
				;- - ((r < g) And (r < b))
			Case 6 ;If ((r < g) And (r < b)) Or (r < seuil)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_06 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 02] ;r
				! cmp al, byte [r15 + 56] ;seuil
				! jb saut_Color_06_ok
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! ja saut_Color_06_end
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! ja saut_Color_06_end
				! saut_Color_06_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_06_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_06_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_06
				
				;- - ((g < r) And (g < b)) 
			Case 7 ;If ((g < r) And (g < b)) Or (g < seuil)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_07 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 01] ;g
				! cmp al, byte [r15 + 56] ;seuil
				! jb saut_Color_07_ok
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! ja saut_Color_07_end
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! ja saut_Color_07_end
				! saut_Color_07_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_07_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_07_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_07
				
				;- - (b < gb) And (b < r) 
			Case 8 ;If (b < gb) And (b < r) Or (b < seuil) 
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_08 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 00] ;b
				! cmp al, byte [r15 + 56] ;seuil
				! jb saut_Color_08_ok
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! ja saut_Color_08_end
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! ja saut_Color_08_end
				! saut_Color_08_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_08_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_08_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_08
				;- - 
				;- - ((r > g) And (r > b)) 
			Case 9 ;If ((r > g) And (r > b)) Or (r > seuil) 
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_09 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 02] ;r
				! cmp al, byte [r15 + 56] ;seuil
				! jb saut_Color_09_ok
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! jb saut_Color_09_end
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! jb saut_Color_09_end
				! saut_Color_09_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_09_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_09_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_09
				;- - ((g > r) And (g > b)) 
			Case 10 ;If ((g > r) And (g > b)) Or (g > seuil) 
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_10 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 01] ;g
				! cmp al, byte [r15 + 56] ;seuil
				! jb saut_Color_10_ok
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! jb saut_Color_10_end
				! cmp al, byte [r8 + rcx * 4 + 00] ;b
				! jb saut_Color_10_end
				! saut_Color_10_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_10_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_10_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_10
				
				;- - ((b > g) And (b > r)) 
			Case 11 ;If ((b > g) And (b > r)) Or (b > seuil)
				
				! mov r15, [p.v_p]
				! mov r8, [r15 + 00] ;source
				! mov r9, [r15 + 08] ;cible
				! mov r10, [r15 + 16] ;mask
				
				! mov rcx, [p.v_start]
				! boucle_Color_11 : 
				! mov ebx, [r8 + rcx * 4]
				! mov al, [r8 + rcx * 4 + 00] ;b
				! cmp al, byte [r15 + 56] ;seuil
				! jb saut_Color_11_ok
				! cmp al, byte [r8 + rcx * 4 + 02] ;r
				! jb saut_Color_11_end
				! cmp al, byte [r8 + rcx * 4 + 01] ;g
				! jb saut_Color_11_end
				! saut_Color_11_ok : 
				
				! mov rax, 21845
				! movzx r11, bl
				! shr ebx, 8
				! movzx r12, bl
				! shr ebx, 8
				! movzx r13, bl
				! add r11d, r12d
				! add r11d, r13d
				! mul r11d
				! shr eax, 16
				! mov ah, al
				! shl eax, 8
				! mov al, ah
				! mov ebx, eax
				
				! mov eax, 0
				! cmp rax, r10
				! je saut_Color_11_end 
				! mov r13d, ebx ;calcul du mask
				! mov r12d, [r10 + rcx * 4]
				! and r13d, r12d ;modification dans le mask
				! xor r12d, $ffffffff
				! mov ebx, [r8 + rcx * 4]
				! and ebx, r12d
				! or ebx, r13d ;ajout de la partie hors du mask
				
				! saut_Color_11_end : 
				! mov [r9 + rcx * 4], ebx
				! inc rcx
				! cmp rcx, [p.v_stop]
				! jb boucle_Color_11
				
				;- - 
				
		EndSelect
		
		! mov rax, [p.v_s]
		! mov r10, [rax + 000]
		! mov r11, [rax + 008]
		! mov r12, [rax + 016]
		! mov r13, [rax + 024]
		! mov r15, [rax + 032]
		
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Color_Effect_thread(i)
		
		Protected tt, start, stop, p, s
		p = @param()
		
		tt = ( param(3) * param(4) ) / param(5)
		start = tt * i
		stop = tt * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		Protected Dim Reg_memory.q(2 * 8)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! mov [rax + 000], r10
		! mov [rax + 008], r12
		! mov [rax + 016], r13
		
		Select param(6)
			Case 0 
				If param(2) = 0
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_0 : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 201
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					! movd [r9 + rdx * 4], xmm0
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_0 
				Else
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! mov r10, [rax + 16] ;mask
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_0bis : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 201
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					
					! movd ecx, xmm0
					! mov r13d, ecx ;calcul du mask
					! mov r12d, [r10 + rdx * 4]
					! and r13d, r12d ;modification dans le mask
					! xor r12d, $ffffffff
					! mov ecx, [r8 + rdx * 4]
					! and ecx, r12d
					! or ecx, r13d ;ajout de la partie hors du mask 
					
					! mov [r9 + rdx * 4], ecx
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_0bis 
				EndIf
				
			Case 1 
				If param(2) = 0
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_1 : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 210
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					! movd [r9 + rdx * 4], xmm0
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_1
				Else 
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! mov r10, [rax + 16] ;mask
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_1bis : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 210
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					
					! movd ecx, xmm0
					! mov r13d, ecx ;calcul du mask
					! mov r12d, [r10 + rdx * 4]
					! and r13d, r12d ;modification dans le mask
					! xor r12d, $ffffffff
					! mov ecx, [r8 + rdx * 4]
					! and ecx, r12d
					! or ecx, r13d ;ajout de la partie hors du mask
					
					! mov [r9 + rdx * 4], ecx
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_1bis 
				EndIf
				
				
			Case 2 
				If param(2) = 0 
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_2 : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 198
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					! movd [r9 + rdx * 4], xmm0
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_2
				Else 
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! mov r10, [rax + 16] ;mask
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_2bis : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 198
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					
					! movd ecx, xmm0
					! mov r13d, ecx ;calcul du mask
					! mov r12d, [r10 + rdx * 4]
					! and r13d, r12d ;modification dans le mask
					! xor r12d, $ffffffff
					! mov ecx, [r8 + rdx * 4]
					! and ecx, r12d
					! or ecx, r13d ;ajout de la partie hors du mask
					
					! mov [r9 + rdx * 4], ecx
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_2bis 
				EndIf
				
			Case 3 
				If param(2) = 0 
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_3 : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 216
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					! movd [r9 + rdx * 4], xmm0
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_3
				Else
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! mov r10, [rax + 16] ;mask
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_3bis : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 216
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					
					! movd ecx, xmm0
					! mov r13d, ecx ;calcul du mask
					! mov r12d, [r10 + rdx * 4]
					! and r13d, r12d ;modification dans le mask
					! xor r12d, $ffffffff
					! mov ecx, [r8 + rdx * 4]
					! and ecx, r12d
					! or ecx, r13d ;ajout de la partie hors du mask
					
					! mov [r9 + rdx * 4], ecx
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_3bis 
				EndIf
				
			Case 4
				If param(2) = 0 
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_4 : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 225
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					! movd [r9 + rdx * 4], xmm0
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_4
				Else 
					! mov rax, [p.v_p]
					! mov r8, [rax + 00] ;source
					! mov r9, [rax + 08] ;cible
					! mov r10, [rax + 16] ;mask
					! pxor xmm3, xmm3
					! mov edx, [p.v_start]
					! color_effect_4bis : 
					! movd xmm0, [r8 + rdx * 4]
					! punpcklbw xmm0, xmm3
					! movq xmm1, xmm0
					! pshuflw xmm1, xmm1, 225
					! paddw xmm0, xmm1
					! psrlw xmm0, 1
					! packuswb xmm0, xmm3 
					
					! movd ecx, xmm0
					! mov r13d, ecx ;calcul du mask
					! mov r12d, [r10 + rdx * 4]
					! and r13d, r12d ;modification dans le mask
					! xor r12d, $ffffffff
					! mov ecx, [r8 + rdx * 4]
					! and ecx, r12d
					! or ecx, r13d ;ajout de la partie hors du mask
					
					! mov [r9 + rdx * 4], ecx
					! inc rdx
					! cmp rdx, [p.v_stop]
					! jb color_effect_4bis 
				EndIf 
				
		EndSelect
		
		! mov rax, [p.v_s]
		! mov r10, [rax + 000]
		! mov r12, [rax + 008]
		! mov r13, [rax + 016]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Contrast_mask_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		p = param()
		
		Protected Dim Reg_memory.q(4 * 4 + 3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! mov [rax + 00], r10
		! mov [rax + 08], r11
		! mov [rax + 16], r12
		! mov [rax + 24], r13
		! movdqu [rax + 032], xmm4
		! movdqu [rax + 048], xmm5
		! movdqu [rax + 064], xmm6
		
		! mov rdx, [p.v_p]
		! mov ecx, [rdx + 64];param(6) = option r
		! mov [rax + 00], ecx
		! mov ecx, [rdx + 56];param(7) = option g
		! mov [rax + 04], ecx
		! mov ecx, [rdx + 48];param(8) = option b
		! mov [rax + 08], ecx
		! movdqu xmm4, [rax + 00]
		! cvtdq2ps xmm4, xmm4
		
		! pxor xmm3, xmm3
		! mov eax, 127
		! movd xmm5, eax
		! pshufd xmm5, xmm5, 0
		! cvtdq2ps xmm5, xmm5
		
		! mov eax, 255
		! movd xmm6, eax
		! pshufd xmm6, xmm6, 0
		! cvtdq2ps xmm6, xmm6
		
		! mov rax, [p.v_p]
		! mov r8, [rax + 00] ;source
		! mov r9, [rax + 08] ;cible
		! mov r10, [rax + 16] ;mask
		! mov rdx, [p.v_start]
		! Blueoucle_mask : 
		! movd xmm0, [r8 + rdx * 4]
		! punpcklbw xmm0, xmm3 ;coversion 8bits - > 16bits
		! punpcklwd xmm0, xmm3 ;coversion 16bits - > 32bits 
		! cvtdq2ps xmm0, xmm0
		! movups xmm1, xmm0 ;save (pixel) 
		! movups xmm2, xmm4 ;save xmm13 ( opt )
		! subps xmm0, xmm5 ;( pixel - 127 )
		! divps xmm2, xmm6 ;option / 255
		! mulps xmm2, xmm0 ;(option / 255) * ( pixel - 127 )
		! addps xmm1, xmm2 
		! cvtps2dq xmm1, xmm1
		! packusdw xmm1, xmm3
		! packuswb xmm1, xmm3
		
		! movd r13d, xmm1 ;calcul du mask
		! mov r12d, [r10 + rdx * 4]
		! and r13d, r12d ;modification dans le mask
		! xor r12d, $ffffffff
		! mov r11d, [r8 + rdx * 4]
		! and r11d, r12d
		! or r11d, r13d ;ajout de la partie hors du mask
		
		! mov [r9 + rdx * 4], r11d
		! inc rdx
		! cmp rdx, [p.v_stop]
		! jb Blueoucle_mask 
		
		! mov rax, [p.v_s]
		! mov r10, [rax + 00]
		! mov r11, [rax + 08]
		! mov r12, [rax + 16]
		! mov r13, [rax + 24]
		! movdqu xmm4, [rax + 032]
		! movdqu xmm5, [rax + 048]
		! movdqu xmm6, [rax + 064]
		FreeArray(Reg_memory())
		
		
	EndProcedure
	
	Procedure Contrast_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		p = param()
		
		Protected Dim Reg_memory.q(4 * 4 + 3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! movdqu [rax + 016], xmm4
		! movdqu [rax + 032], xmm5
		! movdqu [rax + 048], xmm6
		
		! mov rdx, [p.v_p]
		! mov ecx, [rdx + 64];param(6) = option r
		! mov [rax + 00], ecx
		! mov ecx, [rdx + 56];param(7) = option g
		! mov [rax + 04], ecx
		! mov ecx, [rdx + 48];param(8) = option b
		! mov [rax + 08], ecx
		! movdqu xmm4, [rax + 00]
		! cvtdq2ps xmm4, xmm4
		
		! pxor xmm3, xmm3
		! mov eax, 127
		! movd xmm5, eax
		! pshufd xmm5, xmm5, 0
		! cvtdq2ps xmm5, xmm5
		
		! mov eax, 255
		! movd xmm6, eax
		! pshufd xmm6, xmm6, 0
		! cvtdq2ps xmm6, xmm6
		
		! mov rax, [p.v_p]
		! mov r8, [rax + 00]
		! mov r9, [rax + 08]
		! mov rdx, [p.v_start]
		! Blueoucle : 
		! movd xmm0, [r8 + rdx * 4]
		! punpcklbw xmm0, xmm3 ;coversion 8bits - > 16bits
		! punpcklwd xmm0, xmm3 ;coversion 16bits - > 32bits 
		! cvtdq2ps xmm0, xmm0 ;xmm0.f = xmm0.i
		! movups xmm1, xmm0 ;save (pixel) 
		! movups xmm2, xmm4 ;save xmm13 ( opt )
		! subps xmm0, xmm5 ;( pixel - 127 )
		! divps xmm2, xmm6 ;option / 255
		! mulps xmm2, xmm0 ;(option / 255) * ( pixel - 127 )
		! addps xmm1, xmm2 
		! cvtps2dq xmm1, xmm1 ;xmm0.i = xmm0.f
		! packusdw xmm1, xmm3 ;conversion 32bits - > 16bits
		! packuswb xmm1, xmm3 ;conversion 16bits - > 8bits
		! movd [r9 + rdx * 4], xmm1
		! inc rdx
		! cmp rdx, [p.v_stop]
		! jb Blueoucle 
		
		! mov rax, [p.v_s]
		! movdqu xmm4, [rax + 016]
		! movdqu xmm5, [rax + 032]
		! movdqu xmm6, [rax + 048]
		FreeArray(Reg_memory())
		
		
	EndProcedure
	
	Procedure EmbossV1(i) ;2 pixels
		
		Protected start, stop, p, s, d.f, p1, p2, p3
		
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * ( i + 1 )
		If i = param(5) - 1
			If stop < param(4) : stop = param(4) : EndIf
		EndIf
		
		d.f = param(6)
		d = d / 10
		
		Protected Dim Reg_memory.q(3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! movdqu [rax + 000], xmm4
		! movdqu [rax + 016], xmm5
		! movdqu [rax + 032], xmm6
		
		! pxor xmm5, xmm5
		! mov eax, $55
		! movd xmm4, eax
		! pshufd xmm4, xmm4, 0
		! movups xmm3, [p.v_d]
		! pshufd xmm3, xmm3, 0 ;xmm3 = d : d : d : d
		
		! mov rax, [p.v_p]
		! movd xmm12, [rax + 56] ;light
		! pshufd xmm12, xmm12, 0 ;xmm2 = param(7)(32bits) : param(7)(32bits) : param(7)(32bits) : param(7)(32bits)
		
		;For y = start To stop
		! mov r8, [p.v_start]
		! EmbossV1_boucle_y : 
		
		! mov r9, [p.v_p]
		;p1 = param(0) + (PeekL(param(9) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 72] ;param(9)
		Emboss_pos_macro()
		! mov [p.v_p1], rax
		
		;p2 = param(0) + (PeekL(param(11) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 88] ;param(11)
		Emboss_pos_macro()
		! mov [p.v_p2], rax
		
		;p3 = param(1) + (y * (param(3)) << 2)
		Emboss_pokel_macro()
		! mov [p.v_p3], rax
		
		! xor rdx, rdx
		! EmbossV1_boucle_x : ;For x = 0 To param(3) - 1 
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 64] ;(param(10) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p1]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 80] ;(param(12) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p2]
		! movd xmm1, [rcx]
		! punpcklbw xmm1, xmm5 ;coversion 8bits - > 16bits
		! punpcklwd xmm0, xmm5 ;coversion 16bits - > 32bits 
		! punpcklwd xmm1, xmm5 ;coversion 16bits - > 32bits 
		
		! psubd xmm0, xmm1 ;r = (r1 - r2) : g = (g1 - g2) : b = (b1 - b2)
		! cvtdq2ps xmm0, xmm0 ;r.f = r.i : g.f = g.i : b.f = b.i
		! mulps xmm0, xmm3 ;r * d : g * d : b * d
		! cvtps2dq xmm0, xmm0 ;r.i = r.f ...
		! paddd xmm0, xmm12 ;param(7) + ( r * d ) ...
		
		Emboss_grayscale_macro()
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add rcx, [p.v_p3]
		! mov [rcx], eax
		
		! inc rdx
		! cmp rdx, [r9 + 24]
		! jb EmbossV1_boucle_x ;next
		! inc r8
		! cmp r8, [p.v_stop]
		! jb EmbossV1_boucle_y ;next
		
		! mov rax, [p.v_s]
		! movdqu xmm4, [rax + 000]
		! movdqu xmm5, [rax + 016]
		! movdqu xmm6, [rax + 032]
		
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure EmbossV2(i) ;3 pixels
		
		Protected start, stop, p, s, d.f, p1, p2, p3, p4 
		
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * ( i + 1 )
		If i = param(5) - 1
			If stop < param(4) : stop = param(4) : EndIf
		EndIf
		
		d.f = param(6)
		d = d / 10
		
		Protected Dim Reg_memory.q(3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! movdqu [rax + 000], xmm4
		! movdqu [rax + 016], xmm5
		! movdqu [rax + 032], xmm6
		
		! pxor xmm5, xmm5
		! mov eax, $55
		! movd xmm4, eax
		! pshufd xmm4, xmm4, 0
		! movups xmm3, [p.v_d]
		! pshufd xmm3, xmm3, 0 ;xmm3 = d : d : d : d
		
		! mov rax, [p.v_p]
		! movd xmm12, [rax + 56] ;light
		! pshufd xmm12, xmm12, 0 ;xmm2 = param(7)(32bits) : param(7)(32bits) : param(7)(32bits) : param(7)(32bits)
		
		;For y = start To stop
		! mov r8, [p.v_start]
		! EmbossV2_boucle_y : 
		
		! mov r9, [p.v_p]
		;p1 = param(0) + (PeekL(param(9) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 72] ;param(9)
		Emboss_pos_macro()
		! mov [p.v_p1], rax
		
		;p2 = param(0) + (PeekL(param(11) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 88] ;param(11)
		Emboss_pos_macro()
		! mov [p.v_p2], rax
		
		;p3 = param(0) + (PeekL(param(13) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 104] ;param(13)
		Emboss_pos_macro()
		! mov [p.v_p3], rax
		
		;p4 = param(1) + (y * (param(3)) << 2)
		Emboss_pokel_macro()
		! mov [p.v_p4], rax
		
		! xor rdx, rdx
		! EmbossV2_boucle_x : ;For x = 0 To param(3) - 1 
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 64] ;(param(10) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p1]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 80] ;(param(11) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p2]
		! movd xmm1, [rcx]
		! punpcklbw xmm1, xmm5 ;coversion 8bits - > 16bits
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 96] ;(param(12) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p3]
		! movd xmm2, [rcx]
		! punpcklbw xmm2, xmm5 ;coversion 8bits - > 16bits
		
		! punpcklwd xmm1, xmm5 ;coversion 16bits - > 32bits 
		;r = (param(7) + ((r1 * 2) - (r2 + r3)) * p)
		! paddd xmm1, xmm1 ;r2 = r2 * 2
		! paddw xmm0, xmm2 ;r1 = r1 + r3
		! punpcklwd xmm0, xmm5 ;coversion 16bits - > 32bits 
		! psubd xmm0, xmm1 ;r = (r1 + r3) - ( r2 * 2 )
		
		! cvtdq2ps xmm0, xmm0 ;r.f = r.i : g.f = g.i : b.f = b.i
		! mulps xmm0, xmm3 ;r * d : g * d : b * d
		! cvtps2dq xmm0, xmm0 ;r.i = r.f ...
		
		! paddd xmm0, xmm12 ;param(7) + ( r * d ) ...
		
		Emboss_grayscale_macro()
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add rcx, [p.v_p4]
		! mov [rcx], eax
		
		! inc rdx
		! cmp rdx, [r9 + 24]
		! jb EmbossV2_boucle_x ;next
		! inc r8
		! cmp r8, [p.v_stop]
		! jb EmbossV2_boucle_y ;next
		
		! mov rax, [p.v_s]
		! movdqu xmm4, [rax + 000]
		! movdqu xmm5, [rax + 016]
		! movdqu xmm6, [rax + 032]
		
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure EmbossV3(i) ;5 pixels
		
		Protected start, stop, p, s, d.f, p0, p1, p2, p3, p4, p5
		
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * ( i + 1 )
		If i = param(5) - 1
			If stop < param(4) : stop = param(4) : EndIf
		EndIf
		
		d.f = param(6)
		d = d / 10
		
		Protected Dim Reg_memory.q(3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! movdqu [rax + 000], xmm4
		! movdqu [rax + 016], xmm5
		! movdqu [rax + 032], xmm6
		
		! pxor xmm5, xmm5
		! mov eax, $55
		! movd xmm4, eax
		! pshufd xmm4, xmm4, 0
		! movups xmm6, [p.v_d]
		! pshufd xmm6, xmm6, 0 ;xmm3 = d : d : d : d
		
		! mov rax, [p.v_p]
		! movd xmm12, [rax + 56] ;light
		! pshufd xmm12, xmm12, 0 ;xmm2 = param(7)(32bits) : param(7)(32bits) : param(7)(32bits) : param(7)(32bits)
		
		;For y = start To stop
		! mov r8, [p.v_start]
		! EmbossV3_boucle_y : 
		
		! mov r9, [p.v_p]
		
		;p1 = param(0) + ( y * 4 * (param(3)) << 2)
		! mov rdx, r8
		! mov rax, [r9 + 24] ;param(3)
		! mul rdx
		! shl rax, 2
		! add rax, [r9 + 00] ;param(0)
		! mov [p.v_p0], rax
		
		;p1 = param(0) + (PeekL(param(9) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 72] ;param(9)
		Emboss_pos_macro()
		! mov [p.v_p1], rax
		
		;p2 = param(0) + (PeekL(param(11) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 88] ;param(11)
		Emboss_pos_macro()
		! mov [p.v_p2], rax
		
		;p3 = param(0) + (PeekL(param(13) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 104] ;param(13)
		Emboss_pos_macro()
		! mov [p.v_p3], rax
		
		;p4 = param(0) + (PeekL(param(15) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 120] ;param(15)
		Emboss_pos_macro()
		! mov [p.v_p4], rax
		
		;p5 = param(1) + (y * (param(3)) << 2)
		Emboss_pokel_macro()
		! mov [p.v_p5], rax
		
		! xor rdx, rdx
		! EmbossV3_boucle_x : ;For x = 0 To param(3) - 1 
		
		! pxor xmm0, xmm0
		! pxor xmm1, xmm1
		! mov r9, [p.v_p]
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 64] ;(param(10) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p1]
		! movd xmm1, [rcx]
		! punpcklbw xmm1, xmm5 ;coversion 8bits - > 16bits
		
		! mov r9, [p.v_p]
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 80] ;(param(11) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p2]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov r9, [p.v_p]
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 96] ;(param(12) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p3]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov r9, [p.v_p]
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add ecx, [r9 + 112] ;(param(13) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p4]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		! punpcklwd xmm1, xmm5 ;coversion 16bits - > 32bits
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add rcx, [p.v_p0]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! punpcklwd xmm0, xmm5 ;coversion 16bits - > 32bits
		
		! paddd xmm0, xmm0
		! paddd xmm0, xmm0
		
		;r = (param(7) + (r0 * 4) - (r1 + r2 + r3 + r4) 
		! psubd xmm0, xmm1 ;
		
		! cvtdq2ps xmm0, xmm0 ;r.f = r.i : g.f = g.i : b.f = b.i
		! mulps xmm0, xmm6 ;r * d : g * d : b * d
		! cvtps2dq xmm0, xmm0 ;r.i = r.f ...
		
		! paddd xmm0, xmm12 ;param(7) + ( r * d ) ...
		
		Emboss_grayscale_macro()
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add rcx, [p.v_p5]
		! mov [rcx], eax
		
		! mov rax, [p.v_p]
		! inc rdx
		! cmp rdx, [rax + 24]
		! jb EmbossV3_boucle_x ;next
		! inc r8
		! cmp r8, [p.v_stop]
		! jb EmbossV3_boucle_y ;next
		
		
		! mov rax, [p.v_s]
		! movdqu xmm4, [rax + 000]
		! movdqu xmm5, [rax + 016]
		! movdqu xmm6, [rax + 032]
		
		FreeArray(Reg_memory())
	EndProcedure
	
	Procedure EmbossV4(i) ;6 pixels
		
		Protected start, stop, p, s, d.f, p1, p2, p3, p4, p5, p6, p7
		
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * ( i + 1 )
		If i = param(5) - 1
			If stop < param(4) : stop = param(4) : EndIf
		EndIf
		
		d.f = param(6)
		d = d / 10
		
		Protected Dim Reg_memory.q(3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! movdqu [rax + 000], xmm4
		! movdqu [rax + 016], xmm5
		! movdqu [rax + 032], xmm6
		
		! pxor xmm5, xmm5
		! mov eax, $55
		! movd xmm4, eax
		! pshufd xmm4, xmm4, 0
		! movups xmm6, [p.v_d]
		! pshufd xmm6, xmm6, 0 ;xmm3 = d : d : d : d
		
		! mov rax, [p.v_p]
		! movd xmm12, [rax + 56] ;light
		! pshufd xmm12, xmm12, 0 ;xmm2 = param(7)(32bits) : param(7)(32bits) : param(7)(32bits) : param(7)(32bits)
		
		;For y = start To stop
		! mov r8, [p.v_start]
		! EmbossV4_boucle_y : 
		
		! mov r9, [p.v_p]
		
		;p1 = param(0) + (PeekL(param(9) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 72] ;param(9)
		Emboss_pos_macro()
		! mov [p.v_p1], rax
		
		;p2 = param(0) + (PeekL(param(11) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 88] ;param(11)
		Emboss_pos_macro()
		! mov [p.v_p2], rax
		
		;p3 = param(0) + (PeekL(param(13) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 104] ;param(13)
		Emboss_pos_macro()
		! mov [p.v_p3], rax
		
		;p4 = param(0) + (PeekL(param(15) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 120] ;param(15)
		Emboss_pos_macro()
		! mov [p.v_p4], rax
		
		;p5 = param(0) + (PeekL(param(15) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 136] ;param(15)
		Emboss_pos_macro()
		! mov [p.v_p5], rax
		
		;p6 = param(0) + (PeekL(param(15) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 152] ;param(15)
		Emboss_pos_macro()
		! mov [p.v_p6], rax
		
		;p5 = param(1) + (y * (param(3)) << 2)
		Emboss_pokel_macro()
		! mov [p.v_p7], rax
		
		! xor rdx, rdx
		! EmbossV4_boucle_x : ;For x = 0 To param(3) - 1 
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! mov rax, rcx
		! add ecx, [r9 + 64] ;(param(10) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p1]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm0, xmm0 ;X2
		
		! mov rcx, rax
		! add ecx, [r9 + 80] ;(param(11) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p2]
		! movd xmm1, [rcx]
		! punpcklbw xmm1, xmm5 ;coversion 8bits - > 16bits
		
		! mov rcx, rax
		! add ecx, [r9 + 96] ;(param(12) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p3]
		! movd xmm2, [rcx]
		! punpcklbw xmm2, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm0, xmm1
		! paddw xmm0, xmm2
		
		! mov rcx, rax
		! add ecx, [r9 + 112] ;(param(13) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p4]
		! movd xmm1, [rcx]
		! punpcklbw xmm1, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm1
		
		! mov rcx, rax
		! add ecx, [r9 + 128] ;(param(11) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p5]
		! movd xmm2, [rcx]
		! punpcklbw xmm2, xmm5 ;coversion 8bits - > 16bits
		
		! mov rcx, rax
		! add ecx, [r9 + 144] ;(param(12) + x * 4)
		! mov ecx, [rcx]
		! add rcx, [p.v_p6]
		! movd xmm3, [rcx]
		! punpcklbw xmm3, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm2
		! paddw xmm1, xmm3
		
		! punpcklwd xmm0, xmm5 ;coversion 16bits - > 32bits
		! punpcklwd xmm1, xmm5 ;coversion 16bits - > 32bits
		
		;r = (param(7) + (r0 * 2 + r1 + r2) - (r3 * 2 + r4 + r5) 
		! psubd xmm0, xmm1 ;
		
		! cvtdq2ps xmm0, xmm0 ;r.f = r.i : g.f = g.i : b.f = b.i
		! mulps xmm0, xmm6 ;r * d : g * d : b * d
		! cvtps2dq xmm0, xmm0 ;r.i = r.f ...
		
		! paddd xmm0, xmm12 ;param(7) + ( r * d ) ...
		
		Emboss_grayscale_macro()
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add rcx, [p.v_p7]
		! mov [rcx], eax
		
		! mov rax, [p.v_p]
		! inc rdx
		! cmp rdx, [rax + 24]
		! jb EmbossV4_boucle_x ;next
		! inc r8
		! cmp r8, [p.v_stop]
		! jb EmbossV4_boucle_y ;next
		
		! mov rax, [p.v_s]
		! movdqu xmm4, [rax + 000]
		! movdqu xmm5, [rax + 016]
		! movdqu xmm6, [rax + 032]
		
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure EmbossV5(i) ;9 pixels
		
		Protected start, stop, p, s, d.f, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9
		
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * ( i + 1 )
		If i = param(5) - 1
			If stop < param(4) : stop = param(4) : EndIf
		EndIf
		
		d.f = param(6)
		d = d / 10
		
		Protected Dim Reg_memory.q(3 * 16)
		s = @reg_memory()
		! mov rax, [p.v_s]
		! movdqu [rax + 000], xmm4
		! movdqu [rax + 016], xmm5
		! movdqu [rax + 032], xmm6
		
		! pxor xmm5, xmm5
		! mov eax, $55
		! movd xmm4, eax
		! pshufd xmm4, xmm4, 0
		! movups xmm6, [p.v_d]
		! pshufd xmm6, xmm6, 0 ;xmm3 = d : d : d : d
		
		! mov rax, [p.v_p]
		! movd xmm12, [rax + 56] ;light
		! pshufd xmm12, xmm12, 0 ;xmm2 = param(7)(32bits) : param(7)(32bits) : param(7)(32bits) : param(7)(32bits)
		
		;For y = start To stop
		! mov r8, [p.v_start]
		! EmbossV5_boucle_y : 
		
		! mov r9, [p.v_p]
		
		;p1 = param(0) + (PeekL(param(9) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 72] ;param(9)
		Emboss_pos_macro()
		! mov [p.v_p1], rax
		! mov [p.v_p2], rax
		! mov [p.v_p3], rax
		
		;p2 = param(0) + (PeekL(param(11) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 88] ;param(11)
		Emboss_pos_macro()
		! mov [p.v_p4], rax
		! mov [p.v_p5], rax
		! mov [p.v_p9], rax
		
		;p3 = param(0) + (PeekL(param(13) + y * 4) * (param(3)) << 2)
		! mov rcx, [r9 + 104] ;param(13)
		Emboss_pos_macro()
		! mov [p.v_p6], rax
		! mov [p.v_p7], rax
		! mov [p.v_p8], rax
		
		;p5 = param(1) + (y * (param(3)) << 2)
		Emboss_pokel_macro()
		! mov [p.v_p0], rax
		
		! xor rdx, rdx
		! EmbossV5_boucle_x : ;For x = 0 To param(3) - 1 
		
		! mov rcx, rdx
		! shl rcx, 2
		! add ecx, [r9 + 64] ;(param(10) + x * 4)
		! mov ecx, [rcx]
		! mov eax, ecx
		! add rcx, [p.v_p1]
		! movd xmm1, [rcx]
		! punpcklbw xmm1, xmm5 ;coversion 8bits - > 16bits
		
		! mov ecx, eax
		! add rcx, [p.v_p4]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov ecx, eax
		! add rcx, [p.v_p6]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov rcx, rdx
		! shl rcx, 2
		! add ecx, [r9 + 96] ;(param(12) + x * 4)
		! mov ecx, [rcx]
		! mov eax, ecx
		! add rcx, [p.v_p3]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov ecx, eax
		! add rcx, [p.v_p5]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov ecx, eax
		! add rcx, [p.v_p8]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0 
		
		! mov rcx, rdx
		! shl rcx, 2
		! add ecx, [r9 + 80] ;(param(11) + x * 4)
		! mov ecx, [rcx]
		! mov eax, ecx
		! add rcx, [p.v_p7]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov ecx, eax
		! add rcx, [p.v_p2]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! paddw xmm1, xmm0
		
		! mov ecx, eax
		! add rcx, [p.v_p9]
		! movd xmm0, [rcx]
		! punpcklbw xmm0, xmm5 ;coversion 8bits - > 16bits
		! punpcklwd xmm0, xmm5 ;coversion 16bits - > 32bits
		! pslld xmm0, 3 ;X8
		
		! punpcklwd xmm1, xmm5 ;coversion 16bits - > 32bits
		
		;r = (r9 * 8) - (r1 + r2 + ...r7 + r8) 
		! psubd xmm0, xmm1 ;
		
		! cvtdq2ps xmm0, xmm0 ;r.f = r.i : g.f = g.i : b.f = b.i
		! mulps xmm0, xmm6 ;r * d : g * d : b * d
		! cvtps2dq xmm0, xmm0 ;r.i = r.f ...
		
		! paddd xmm0, xmm12 ;param(7) + ( r * d ) ...
		
		Emboss_grayscale_macro()
		
		! mov rcx, rdx;[p.v_x]
		! shl rcx, 2
		! add rcx, [p.v_p0]
		! mov [rcx], eax
		
		! inc rdx
		! cmp rdx, [r9 + 24]
		! jb EmbossV5_boucle_x ;next 
		
		! inc r8
		! cmp r8, [p.v_stop]
		! jb EmbossV5_boucle_y ;next
		
		! mov rax, [p.v_s]
		! movdqu xmm4, [rax + 000]
		! movdqu xmm5, [rax + 016]
		! movdqu xmm6, [rax + 032]
		
		FreeArray(Reg_memory())
	EndProcedure
	
	Procedure Prewitt_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * (i + 1)
		If i = (param(5) - 1) ;ndt
			If stop < = param(4) : stop = param(4) - 2 : EndIf
		EndIf 
		If stop > param(4) - 2 : stop = param(4) - 2 : EndIf
		
		Protected Dim Reg_memory.q(13 * 8 + 16 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							  ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		! movdqu [rax + 200], xmm6
		! movdqu [rax + 216], xmm7
		! movdqu [rax + 232], xmm8
		! movdqu [rax + 248], xmm9
		! movdqu [rax + 264], xmm10
		! movdqu [rax + 280], xmm11
		! movdqu [rax + 296], xmm12
		! movdqu [rax + 312], xmm13
		! movdqu [rax + 328], xmm14
		! movdqu [rax + 344], xmm15
		
		! mov rcx, [p.v_p]
		
		! mov rax, [p.v_start]
		! imul rax, [rcx + 3 * 8]
		! shl rax, 2 
		! mov r12, [rcx + 0] ;source
		! mov r11, [rcx + 8] ;cible
		! add r12, rax ;source + start
		! add r11, rax ;cible + start 
		
		! add r11, 4
		! mov r15, [rcx + 3 * 8] ;lg
		! shl r15, 2
		! pxor xmm0, xmm0
		! mov eax, [rcx + 6 * 8] ;opt
		! imul eax, $10101
		! movd xmm15, eax
		! punpcklbw xmm15, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 4 * 8] ;ht
		! mov r13, [p.v_start]
		! prewitt_boucle_y : 
		
		! mov rsi, r12
		! mov rdi, r11
		! add r12, r15
		! add r11, r15
		
		! movd xmm1, [rsi]
		! movd xmm2, [rsi + 4]
		! add rsi, r15
		! movd xmm4, [rsi]
		! movd xmm5, [rsi + 4]
		! add rsi, r15
		! movd xmm7, [rsi]
		! movd xmm8, [rsi + 4]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm1, xmm0
		! punpcklbw xmm2, xmm0
		! punpcklbw xmm4, xmm0
		! punpcklbw xmm5, xmm0
		! punpcklbw xmm7, xmm0
		! punpcklbw xmm8, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 3 * 8] ;lg
		! mov r14, rax
		! sub r14, 2
		
		! prewitt_boucle_x : 
		! movd xmm3, [rsi + 8]
		! add rsi, r15
		! movd xmm6, [rsi + 8]
		! add rsi, r15
		! movd xmm9, [rsi + 8]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm3, xmm0
		! punpcklbw xmm6, xmm0
		! punpcklbw xmm9, xmm0
		
		! movups xmm10, xmm1 ;ry = (x1 + x2 + x3) - ( x7 + x8 + x9) x = rgb
		! paddusw xmm10, xmm2
		! paddusw xmm10, xmm3
		! movups xmm11, xmm7
		! paddusw xmm11, xmm8
		! paddusw xmm11, xmm9
		! psubsw xmm10, xmm11
		! pabsw xmm10, xmm10 ;abs
		
		! movups xmm12, xmm3 ;rx = (x3 + x6 + x9) - (x1 + x4 + x7)
		! paddusw xmm12, xmm6
		! paddusw xmm12, xmm9
		! movups xmm13, xmm1
		! paddusw xmm13, xmm4
		! paddusw xmm13, xmm7
		! psubsw xmm12, xmm13
		! pabsw xmm12, xmm12 ;abs
		
		! paddsw xmm10, xmm12 ;x = ((rx + ry) * opt) / 128
		! pmullw xmm10, xmm15
		! psrlw xmm10, 7
		
		! packsswb xmm10, xmm0
		! movd [rdi], xmm10
		
		! add rdi, 4
		! add rsi, 4
		
		! movdqa xmm1, xmm2 ;r1 = r2 : r2 = r3 : r4 = r5 : r5 = r6 : r7 = r8 : r8 = r9
		! movdqa xmm2, xmm3
		! movdqa xmm4, xmm5
		! movdqa xmm5, xmm6
		! movdqa xmm7, xmm8
		! movdqa xmm8, xmm9
		
		! sub r14, 1
		! jnz prewitt_boucle_x
		! inc r13
		! cmp r13, [p.v_stop] 
		! jb prewitt_boucle_y 
		
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		! movdqu xmm6, [rax + 200]
		! movdqu xmm7, [rax + 216]
		! movdqu xmm8, [rax + 232]
		! movdqu xmm9, [rax + 248]
		! movdqu xmm10, [rax + 264]
		! movdqu xmm11, [rax + 280]
		! movdqu xmm12, [rax + 296]
		! movdqu xmm13, [rax + 312]
		! movdqu xmm14, [rax + 328]
		! movdqu xmm15, [rax + 344]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Prewitt_mask_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * (i + 1)
		If i = (param(5) - 1) ;ndt
			If stop < = param(4) : stop = param(4) - 2 : EndIf
		EndIf 
		If stop > param(4) - 2 : stop = param(4) - 2 : EndIf
		
		Protected Dim Reg_memory.q(13 * 8 + 16 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							  ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		! movdqu [rax + 200], xmm6
		! movdqu [rax + 216], xmm7
		! movdqu [rax + 232], xmm8
		! movdqu [rax + 248], xmm9
		! movdqu [rax + 264], xmm10
		! movdqu [rax + 280], xmm11
		! movdqu [rax + 296], xmm12
		! movdqu [rax + 312], xmm13
		! movdqu [rax + 328], xmm14
		! movdqu [rax + 344], xmm15
		
		! mov rcx, [p.v_p]
		
		! mov rax, [p.v_start]
		! imul rax, [rcx + 3 * 8]
		! shl rax, 2 
		! mov r12, [rcx + 00] ;source
		! mov r11, [rcx + 08] ;cible
		! mov rbx, [rcx + 16] ;mask
		! add r12, rax ;source + start
		! add r11, rax ;cible + start 
		! add rbx, rax ;mask + start 
		
		! mov r15, [rcx + 3 * 8] ;lg
		! shl r15, 2
		! pxor xmm0, xmm0
		! mov eax, [rcx + 6 * 8] ;opt
		! imul eax, $10101
		! movd xmm15, eax
		! punpcklbw xmm15, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 4 * 8] ;ht
		! mov r13, [p.v_start]
		! prewitt_boucle_y2 : 
		
		! mov rsi, r12
		! mov rdi, r11
		! mov rdx, rbx
		! add r12, r15
		! add r11, r15
		! add rbx, r15
		
		! movd xmm1, [rsi]
		! movd xmm2, [rsi + 4]
		! add rsi, r15
		! movd xmm4, [rsi]
		! movd xmm5, [rsi + 4]
		! add rsi, r15
		! movd xmm7, [rsi]
		! movd xmm8, [rsi + 4]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm1, xmm0
		! punpcklbw xmm2, xmm0
		! punpcklbw xmm4, xmm0
		! punpcklbw xmm5, xmm0
		! punpcklbw xmm7, xmm0
		! punpcklbw xmm8, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 3 * 8] ;lg
		! mov r14, rax
		! sub r14, 2
		
		! prewitt_boucle_x2 : 
		! movd xmm3, [rsi + 8]
		! add rsi, r15
		! movd xmm6, [rsi + 8]
		! add rsi, r15
		! movd xmm9, [rsi + 8]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm3, xmm0
		! punpcklbw xmm6, xmm0
		! punpcklbw xmm9, xmm0
		
		! movups xmm10, xmm1 ;ry = (x1 + x2 + x3) - ( x7 + x8 + x9) x = rgb
		! paddusw xmm10, xmm2
		! paddusw xmm10, xmm3
		! movups xmm11, xmm7
		! paddusw xmm11, xmm8
		! paddusw xmm11, xmm9
		! psubsw xmm10, xmm11
		! pabsw xmm10, xmm10 ;abs
		
		! movups xmm12, xmm3 ;rx = (x3 + x6 + x9) - (x1 + x4 + x7)
		! paddusw xmm12, xmm6
		! paddusw xmm12, xmm9
		! movups xmm13, xmm1
		! paddusw xmm13, xmm4
		! paddusw xmm13, xmm7
		! psubsw xmm12, xmm13
		! pabsw xmm12, xmm12 ;abs
		
		! paddsw xmm10, xmm12 ;x = ((rx + ry) * opt) / 128
		! pmullw xmm10, xmm15
		! psrlw xmm10, 7
		! packsswb xmm10, xmm0
		;! movd [rdi], xmm10
		
		! movd r8d, xmm10 ;calcul du mask
		! mov r9d, [rdx + 4] ;mask
		! and r8d, r9d ;modification dans le mask
		! xor r9d, $ffffffff
		! mov r10d, [rsi + 4] ;source
		! and r10d, r9d
		! or r10d, r8d ;ajout de la partie hors du mask
		! mov [rdi], r10d
		
		! add rdi, 4
		! add rsi, 4
		! add rdx, 4
		
		! movdqa xmm1, xmm2 ;r1 = r2 : r2 = r3 : r4 = r5 : r5 = r6 : r7 = r8 : r8 = r9
		! movdqa xmm2, xmm3
		! movdqa xmm4, xmm5
		! movdqa xmm5, xmm6
		! movdqa xmm7, xmm8
		! movdqa xmm8, xmm9
		
		! sub r14, 1
		! jnz prewitt_boucle_x2
		! inc r13
		! cmp r13, [p.v_stop] 
		! jb prewitt_boucle_y2
		
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		! movdqu xmm6, [rax + 200]
		! movdqu xmm7, [rax + 216]
		! movdqu xmm8, [rax + 232]
		! movdqu xmm9, [rax + 248]
		! movdqu xmm10, [rax + 264]
		! movdqu xmm11, [rax + 280]
		! movdqu xmm12, [rax + 296]
		! movdqu xmm13, [rax + 312]
		! movdqu xmm14, [rax + 328]
		! movdqu xmm15, [rax + 344]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Roberts_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * (i + 1)
		If i = (param(5) - 1) ;ndt
			If stop < param(4) : stop = param(4) - 1 : EndIf
		EndIf 
		If stop > param(4) - 1 : stop = param(4) - 1 : EndIf
		
		Protected Dim Reg_memory.q(13 * 8 + 6 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							 ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		
		! mov rcx, [p.v_p]
		
		! pxor xmm0, xmm0
		! mov eax, [rcx + 6 * 8] ;opt
		! imul eax, $10101
		! movd xmm5, eax
		! punpcklbw xmm5, xmm0
		
		! mov eax, [ecx + 3 * 8] ;lg
		! mov r10, rax
		! dec r10 ;r10 = lg - 1
		
		! mov eax, [p.v_stop];[ecx + 4 * 8] ;ht
		! mov r11, rax
		
		! mov r9, [p.v_start] ;ht
		! mov eax, [ecx + 3 * 8] ;lg
		! mul r9
		! shl rax, 2
		! mov r9, rax
		
		! mov eax, [ecx + 3 * 8] ;lg
		! shl eax, 2
		! mov rsi, [rcx + 00] ;source
		! add rsi, r9
		! mov rdi, rsi
		! add rdi, rax
		! mov rdx, [rcx + 1 * 8] ;cible
		! add rdx, r9
		
		! mov r9, [p.v_start] ;ht
		! robert_boucle_y : 
		
		! movd xmm1, [rsi]
		! movd xmm3, [rdi]
		! punpcklbw xmm1, xmm0
		! punpcklbw xmm3, xmm0
		
		! xor r8, r8
		! robert_boucle_x : 
		
		! movd xmm2, [rsi + r8 * 4 + 4]
		! movd xmm4, [rdi + r8 * 4 + 4]
		! punpcklbw xmm2, xmm0
		! punpcklbw xmm4, xmm0
		
		! movq xmm10, xmm1 ;r = (Abs(Abs(rx) + Abs(ry)) * Filter_Roberts_opt)
		! psubsw xmm10, xmm4
		! pabsw xmm10, xmm10 ;abs
		
		! movq xmm11, xmm2 ;
		! psubsw xmm11, xmm3
		! pabsw xmm11, xmm11 ;abs
		
		! paddsw xmm10, xmm11 ;x = ((rx + ry) * opt) / 128
		! pmullw xmm10, xmm5
		! psrlw xmm10, 7
		
		! packsswb xmm10, xmm0
		! movd [rdx + r8 * 4], xmm10
		
		! movq xmm1, xmm2 ;r1 = r2
		! movq xmm3, xmm4
		
		! inc r8
		! cmp r8, r10 ;cmp (lg - 1)
		! jb robert_boucle_x
		! mov eax, [ecx + 3 * 8] ;lg
		! shl eax, 2
		! add rdx, rax 
		! add rsi, rax
		! add rdi, rax
		! inc r9
		! cmp r9, r11 ;cmp (ht - 1) 
		! jb robert_boucle_y 
		
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Roberts_mask_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * (i + 1)
		If i = (param(5) - 1) ;ndt
			If stop < param(4) : stop = param(4) - 1 : EndIf
		EndIf 
		If stop > param(4) - 1 : stop = param(4) - 1 : EndIf
		
		Protected Dim Reg_memory.q(13 * 8 + 6 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							 ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		
		! mov rcx, [p.v_p]
		
		! pxor xmm0, xmm0
		! mov eax, [rcx + 6 * 8] ;opt
		! imul eax, $10101
		! movd xmm5, eax
		! punpcklbw xmm5, xmm0
		
		! mov eax, [ecx + 3 * 8] ;lg
		! mov r10, rax
		! dec r10 ;r10 = lg - 1
		
		! mov r9, [p.v_start] ;ht
		! mov eax, [ecx + 3 * 8] ;lg
		! mul r9
		! shl rax, 2
		! mov r9, rax
		
		! mov eax, [ecx + 3 * 8] ;lg
		! shl eax, 2
		! mov rsi, [rcx + 00] ;source
		! add rsi, r9
		! mov rdi, rsi
		! add rdi, rax
		! mov rdx, [rcx + 1 * 8] ;cible
		! add rdx, r9
		! mov r11, [rcx + 2 * 8] ;mask
		! add r11, r9
		
		! mov r9, [p.v_start] ;ht
		! robert_boucle_y2 : 
		
		! movd xmm1, [rsi]
		! movd xmm3, [rdi]
		! punpcklbw xmm1, xmm0
		! punpcklbw xmm3, xmm0
		
		! xor r8, r8
		! robert_boucle_x2 : 
		
		! movd xmm2, [rsi + r8 * 4 + 4]
		! movd xmm4, [rdi + r8 * 4 + 4]
		! punpcklbw xmm2, xmm0
		! punpcklbw xmm4, xmm0
		
		! movq xmm10, xmm1 ;r = (Abs(Abs(rx) + Abs(ry)) * Filter_Roberts_opt)
		! psubsw xmm10, xmm4
		! pabsw xmm10, xmm10 ;abs
		
		! movq xmm11, xmm2 ;
		! psubsw xmm11, xmm3
		! pabsw xmm11, xmm11 ;abs
		
		! paddsw xmm10, xmm11 ;x = ((rx + ry) * opt) / 128
		! pmullw xmm10, xmm5
		! psrlw xmm10, 7
		
		! packsswb xmm10, xmm0
		
		! movd r13d, xmm10 ;calcul du mask
		! mov r12d, [r11 + r8 * 4] ;mask
		! and r13d, r12d ;modification dans le mask
		! xor r12d, $ffffffff
		! mov r14d, [rsi + r8 * 4] ;source
		! and r14d, r12d
		! or r14d, r13d ;ajout de la partie hors du mask
		! mov [rdx + r8 * 4], r14d
		
		! movq xmm1, xmm2 ;r1 = r2
		! movq xmm3, xmm4
		
		! inc r8
		! cmp r8, r10 ;cmp (lg - 1)
		! jb robert_boucle_x2
		! mov eax, [ecx + 3 * 8] ;lg
		! shl eax, 2
		! add rdx, rax 
		! add rsi, rax
		! add rdi, rax
		! add r11, rax
		
		! mov rax, [p.v_stop]
		;! dec rax
		! inc r9
		! cmp r9, rax ;cmp (ht - 1) 
		! jb robert_boucle_y2 
		
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Sobel_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * (i + 1)
		If i = (param(5) - 1) ;ndt
			If stop < = param(4) : stop = param(4) - 2 : EndIf
		EndIf 
		If stop > param(4) - 2 : stop = param(4) - 2 : EndIf
		
		Protected Dim Reg_memory.q(13 * 8 + 16 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							  ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		! movdqu [rax + 200], xmm6
		! movdqu [rax + 216], xmm7
		! movdqu [rax + 232], xmm8
		! movdqu [rax + 248], xmm9
		! movdqu [rax + 264], xmm10
		! movdqu [rax + 280], xmm11
		! movdqu [rax + 296], xmm12
		! movdqu [rax + 312], xmm13
		! movdqu [rax + 328], xmm14
		! movdqu [rax + 344], xmm15
		
		! mov rcx, [p.v_p]
		
		! mov rax, [p.v_start]
		! imul rax, [rcx + 3 * 8]
		! shl rax, 2 
		! mov r12, [rcx + 0] ;source
		! mov r11, [rcx + 8] ;cible
		! add r12, rax ;source + start
		! add r11, rax ;cible + start 
		
		! add r11, 4
		! mov r15, [rcx + 3 * 8] ;lg
		! shl r15, 2
		! pxor xmm0, xmm0
		! mov eax, [rcx + 6 * 8] ;opt
		! imul eax, $10101
		! movd xmm15, eax
		! punpcklbw xmm15, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 4 * 8] ;ht
		! mov r13, [p.v_start]
		! Sobel_boucle_y : 
		
		! mov rsi, r12
		! mov rdi, r11
		! add r12, r15
		! add r11, r15
		
		! movd xmm1, [rsi]
		! movd xmm2, [rsi + 4]
		! add rsi, r15
		! movd xmm4, [rsi]
		! movd xmm5, [rsi + 4]
		! add rsi, r15
		! movd xmm7, [rsi]
		! movd xmm8, [rsi + 4]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm1, xmm0
		! punpcklbw xmm2, xmm0
		! punpcklbw xmm4, xmm0
		! punpcklbw xmm5, xmm0
		! punpcklbw xmm7, xmm0
		! punpcklbw xmm8, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 3 * 8] ;lg
		! mov r14, rax
		! sub r14, 2
		
		! Sobel_boucle_x : 
		! movd xmm3, [rsi + 8]
		! add rsi, r15
		! movd xmm6, [rsi + 8]
		! add rsi, r15
		! movd xmm9, [rsi + 8]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm3, xmm0
		! punpcklbw xmm6, xmm0
		! punpcklbw xmm9, xmm0
		
		! movups xmm10, xmm1 ;ry = (x1 + x2 + x3) - ( x7 + x8 + x9) x = rgb
		! movups xmm14, xmm2
		! psllw xmm14, 1
		! paddusw xmm10, xmm14
		! paddusw xmm10, xmm3
		! movups xmm11, xmm7
		! movups xmm14, xmm8
		! psllw xmm14, 1
		! paddusw xmm11, xmm14
		! paddusw xmm11, xmm9
		! psubsw xmm10, xmm11
		! pabsw xmm10, xmm10 ;abs
		
		! movups xmm12, xmm3 ;rx = (x3 + x6 + x9) - (x1 + x4 + x7)
		! movups xmm14, xmm6
		! psllw xmm14, 1
		! paddusw xmm12, xmm14
		! paddusw xmm12, xmm9
		! movups xmm13, xmm1
		! movups xmm14, xmm4
		! psllw xmm14, 1
		! paddusw xmm13, xmm14
		! paddusw xmm13, xmm7
		! psubsw xmm12, xmm13
		! pabsw xmm12, xmm12 ;abs
		
		! paddsw xmm10, xmm12 ;x = ((rx + ry) * opt) / 128
		! pmullw xmm10, xmm15
		! psrlw xmm10, 7
		
		! packsswb xmm10, xmm0
		! movd [rdi], xmm10
		
		! add rdi, 4
		! add rsi, 4
		
		! movdqa xmm1, xmm2 ;r1 = r2 : r2 = r3 : r4 = r5 : r5 = r6 : r7 = r8 : r8 = r9
		! movdqa xmm2, xmm3
		! movdqa xmm4, xmm5
		! movdqa xmm5, xmm6
		! movdqa xmm7, xmm8
		! movdqa xmm8, xmm9
		
		! sub r14, 1
		! jnz Sobel_boucle_x
		! inc r13
		! cmp r13, [p.v_stop] 
		! jb Sobel_boucle_y 
		
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		! movdqu xmm6, [rax + 200]
		! movdqu xmm7, [rax + 216]
		! movdqu xmm8, [rax + 232]
		! movdqu xmm9, [rax + 248]
		! movdqu xmm10, [rax + 264]
		! movdqu xmm11, [rax + 280]
		! movdqu xmm12, [rax + 296]
		! movdqu xmm13, [rax + 312]
		! movdqu xmm14, [rax + 328]
		! movdqu xmm15, [rax + 344]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Sobel_mask_thread(i)
		
		Protected start, stop, p, s
		p = @param()
		
		start = ( param(4) / param(5) ) * i
		stop = ( param(4) / param(5) ) * (i + 1)
		If i = (param(5) - 1) ;ndt
			If stop < = param(4) : stop = param(4) - 2 : EndIf
		EndIf 
		If stop > param(4) - 2 : stop = param(4) - 2 : EndIf
		
		Protected Dim Reg_memory.q(13 * 8 + 16 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		s = @reg_memory()							  ;sauvegarde des registes
		! mov rax, [p.v_s]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		! movdqu [rax + 200], xmm6
		! movdqu [rax + 216], xmm7
		! movdqu [rax + 232], xmm8
		! movdqu [rax + 248], xmm9
		! movdqu [rax + 264], xmm10
		! movdqu [rax + 280], xmm11
		! movdqu [rax + 296], xmm12
		! movdqu [rax + 312], xmm13
		! movdqu [rax + 328], xmm14
		! movdqu [rax + 344], xmm15
		
		! mov rcx, [p.v_p]
		
		! mov rax, [p.v_start]
		! imul rax, [rcx + 3 * 8]
		! shl rax, 2 
		! mov r12, [rcx + 00] ;source
		! mov r11, [rcx + 08] ;cible
		! mov rbx, [rcx + 16] ;mask
		! add r12, rax ;source + start
		! add r11, rax ;cible + start 
		! add rbx, rax ;mask + start 
		
		! mov r15, [rcx + 3 * 8] ;lg
		! shl r15, 2
		! pxor xmm0, xmm0
		! mov eax, [rcx + 6 * 8] ;opt
		! imul eax, $10101
		! movd xmm15, eax
		! punpcklbw xmm15, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 4 * 8] ;ht
		! mov r13, [p.v_start]
		! Sobel_boucle_y2 : 
		
		! mov rsi, r12
		! mov rdi, r11
		! mov rdx, rbx
		! add r12, r15
		! add r11, r15
		! add rbx, r15
		
		! movd xmm1, [rsi]
		! movd xmm2, [rsi + 4]
		! add rsi, r15
		! movd xmm4, [rsi]
		! movd xmm5, [rsi + 4]
		! add rsi, r15
		! movd xmm7, [rsi]
		! movd xmm8, [rsi + 4]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm1, xmm0
		! punpcklbw xmm2, xmm0
		! punpcklbw xmm4, xmm0
		! punpcklbw xmm5, xmm0
		! punpcklbw xmm7, xmm0
		! punpcklbw xmm8, xmm0
		
		! xor rax, rax
		! mov eax, [rcx + 3 * 8] ;lg
		! mov r14, rax
		! sub r14, 2
		
		! Sobel_boucle_x2 : 
		! movd xmm3, [rsi + 8]
		! add rsi, r15
		! movd xmm6, [rsi + 8]
		! add rsi, r15
		! movd xmm9, [rsi + 8]
		! sub rsi, r15
		! sub rsi, r15
		
		! punpcklbw xmm3, xmm0
		! punpcklbw xmm6, xmm0
		! punpcklbw xmm9, xmm0
		
		! movups xmm10, xmm1 ;ry = (x1 + x2 + x3) - ( x7 + x8 + x9) x = rgb
		! movups xmm14, xmm2
		! psllw xmm14, 1
		! paddusw xmm10, xmm14
		! paddusw xmm10, xmm3
		! movups xmm11, xmm7
		! movups xmm14, xmm8
		! psllw xmm14, 1
		! paddusw xmm11, xmm14
		! paddusw xmm11, xmm9
		! psubsw xmm10, xmm11
		! pabsw xmm10, xmm10 ;abs
		
		! movups xmm12, xmm3 ;rx = (x3 + x6 + x9) - (x1 + x4 + x7)
		! movups xmm14, xmm6
		! psllw xmm14, 1
		! paddusw xmm12, xmm14
		! paddusw xmm12, xmm9
		! movups xmm13, xmm1
		! movups xmm14, xmm4
		! psllw xmm14, 1
		! paddusw xmm13, xmm14
		! paddusw xmm13, xmm7
		! psubsw xmm12, xmm13
		! pabsw xmm12, xmm12 ;abs
		
		! paddsw xmm10, xmm12 ;x = ((rx + ry) * opt) / 128
		! pmullw xmm10, xmm15
		! psrlw xmm10, 7
		! packsswb xmm10, xmm0
		;! movd [rdi], xmm10
		
		! movd r8d, xmm10 ;calcul du mask
		! mov r9d, [rdx + 4] ;mask
		! and r8d, r9d ;modification dans le mask
		! xor r9d, $ffffffff
		! mov r10d, [rsi + 4] ;source
		! and r10d, r9d
		! or r10d, r8d ;ajout de la partie hors du mask
		! mov [rdi], r10d
		
		! add rdi, 4
		! add rsi, 4
		! add rdx, 4
		
		! movdqa xmm1, xmm2 ;r1 = r2 : r2 = r3 : r4 = r5 : r5 = r6 : r7 = r8 : r8 = r9
		! movdqa xmm2, xmm3
		! movdqa xmm4, xmm5
		! movdqa xmm5, xmm6
		! movdqa xmm7, xmm8
		! movdqa xmm8, xmm9
		
		! sub r14, 1
		! jnz Sobel_boucle_x2
		! inc r13
		! cmp r13, [p.v_stop] 
		! jb Sobel_boucle_y2
		
		! mov rax, [p.v_s] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		! movdqu xmm6, [rax + 200]
		! movdqu xmm7, [rax + 216]
		! movdqu xmm8, [rax + 232]
		! movdqu xmm9, [rax + 248]
		! movdqu xmm10, [rax + 264]
		! movdqu xmm11, [rax + 280]
		! movdqu xmm12, [rax + 296]
		! movdqu xmm13, [rax + 312]
		! movdqu xmm14, [rax + 328]
		! movdqu xmm15, [rax + 344]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Tint_thread_pb(i) 
		
		Protected start, stop, p, c.l, s.l, d.f, angle.f
		Protected r, g, b, ry, by, y, ryy, byy, gy, var, GYY
		p = @param()
		
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		angle = (3.14 * param(6)) / 180
		c = Cos(angle) * 256
		s = Sin(angle) * 256
		d = 1 / 100
		For i = start * 4 To (stop * 4) - 4 Step 4 
			var = PeekL(param(0) + i) 
			r = ( var >> 16) & 255
			g = ( var >> 8 ) & 255
			b = var & 255 
			
			RY = ( 70 * r - 59 * g - 11 * b ) * d
			BY = ( - 30 * r - 59 * g + 89 * b ) * d
			Y = ( 30 * r + 59 * g + 11 * b ) * d
			
			RYY = ( S * BY + C * RY ) >> 8;
			BYY = ( C * BY - S * RY ) >> 8;
			
			GYY = ( - 51 * RYY - 19 * BYY ) * d
			
			r = Y + RYY 
			g = Y + GYY;
			b = Y + BYY;
			If r < 0 : r = 0 : EndIf
			If g < 0 : g = 0 : EndIf
			If b < 0 : b = 0 : EndIf
			If r > 255 : r = 255 : EndIf
			If g > 255 : g = 255 : EndIf
			If b > 255 : b = 255 : EndIf
			PokeL(param(1) + i, r << 16 + g << 8 + b) 
		Next
		
	EndProcedure
	
	Procedure Tint_thread(i) 
		
		Protected start, stop, p, c.l, s.l, d.f, angle.f, s2.l, m.q
		p = @param()
		
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		angle = (3.14 * param(6)) / 180
		c = Cos(angle) * 256
		s = Sin(angle) * 256
		s2 = - s
		d = 1 / 100
		
		Protected Dim Reg_memory.q(13 * 8 + 16 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		m = @reg_memory()							  ;sauvegarde des registes
		! mov rax, [p.v_m]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		! movdqu [rax + 200], xmm6
		! movdqu [rax + 216], xmm7
		! movdqu [rax + 232], xmm8
		! movdqu [rax + 248], xmm9
		! movdqu [rax + 264], xmm10
		! movdqu [rax + 280], xmm11
		! movdqu [rax + 296], xmm12
		! movdqu [rax + 312], xmm13
		! movdqu [rax + 328], xmm14
		! movdqu [rax + 344], xmm15
		
		! xor rax, rax
		
		! movd xmm4, [p.v_d]
		! pshufd xmm4, xmm4, 0 ;d | d | d | d
		
		! mov rax, $0046ffc5fff5 ;0 | 70 | - 59 | - 11
		! mov rbx, $0000ffffffff
		! movq xmm5, rax
		! movq xmm0, rbx
		! punpcklwd xmm5, xmm0 ;16 - > 32 bits
		
		! mov rax, $ffe2ffc50059 ;0 | - 30 | - 59 | 89
		! mov rbx, $ffffffff0000
		! movq xmm6, rax
		! movq xmm0, rbx
		! punpcklwd xmm6, xmm0 ;16 - > 32
		
		! mov rax, $001e003b000b ;0 | 30 | 59 | 11
		! movq xmm7, rax
		! pxor xmm0, xmm0
		! punpcklwd xmm7, xmm0 ;16 - > 32 
		
		! mov eax, [p.v_c]
		! mov ebx, [p.v_s]
		! shl rbx, 32
		! or rax, rbx
		! movq xmm8, rax ;0 | 0 | sin | cos
		! pslldq xmm8, 8
		
		! mov eax, [p.v_s2]
		! mov ebx, [p.v_c]
		! shl rbx, 32
		! or rax, rbx
		! movq xmm9, rax ;0 | 0 | cos | - sin
		! por xmm8, xmm9
		
		! mov eax, $ffffffcd ;- 51
		! movd xmm9, eax
		! mov eax, $ffffffed ;- 19
		! movd xmm10, eax
		! pslldq xmm10, 8
		! por xmm9, xmm10
		
		! mov rcx, [p.v_p]
		! mov rdx, [rcx + 00] ;source
		! mov rcx, [rcx + 08] ;cible
		
		
		! mov r8, [p.v_start]
		! Tint_saut_01 : 
		
		! movd xmm1, [rdx + r8 * 4] ;peekl
		! punpcklbw xmm1, xmm0 ;08 > 16 
		! punpcklwd xmm1, xmm0 ;16 > 32
		! movdqu xmm2, xmm1
		! movdqu xmm3, xmm1
		
		! pmulld xmm1, xmm5 ;70 * r | - 59 * g | - 11 * b
		! pmulld xmm2, xmm6 ;- 30 * r | - 59 * g | 89 * b
		! pmulld xmm3, xmm7 ;30 * r | 59 * g | 11 * b
		! phaddd xmm1, xmm1 ;0 + (70 * r) | ( - 59 * g) + ( - 11 * b)
		! phaddd xmm2, xmm2
		! phaddd xmm3, xmm3
		! phaddd xmm1, xmm1 ;0 + (70 * r) + ( - 59 * g) + ( - 11 * b)
		! phaddd xmm2, xmm2
		! phaddd xmm3, xmm3
		
		! punpckldq xmm1, xmm2 ;by | ry | by | ry
		! pslldq xmm1, 4 ;ry | by | ry | 0
		! mov eax, $ffff
		! movd xmm2, eax
		! pand xmm3, xmm2
		! por xmm1, xmm3 ;;ry | by | ry | y
		
		! cvtdq2ps xmm1, xmm1
		! mulps xmm1, xmm4
		! cvtps2dq xmm1, xmm1 ;ry * d | by * d | ry * d | y * d
		;RY = ( 70 * r - 59 * g - 11 * b ) * d
		;BY = ( - 30 * r - 59 * g + 89 * b ) * d
		;Y = ( 30 * r + 59 * g + 11 * b ) * d
		
		! movdqu xmm10, xmm1
		! pshufd xmm10, xmm10, 0 ;y | y | y | y
		! psrldq xmm1, 4 ;0 | ry * d | by * d | ry * d
		! movdqu xmm2, xmm1
		
		! punpckldq xmm1, xmm1 ;by | ry | by | ry
		
		! pmulld xmm1, xmm8 ;( S * BY + C * RY ) | ( C * BY - S * RY )
		! phaddd xmm1, xmm1
		! psrad xmm1, 8 ;? | ? | byy | ryy
		! movq xmm2, xmm1
		;RYY = ( S * BY + C * RY ) >> 8;
		;BYY = ( C * BY - S * RY ) >> 8;
		
		! pmulld xmm1, xmm9
		! phaddd xmm1, xmm1
		! cvtdq2ps xmm1, xmm1
		! mulps xmm1, xmm4
		! cvtps2dq xmm1, xmm1 ;xmm1 = GYY = ( - 51 * RYY - 19 * BYY ) * d
		
		! mov rax, $ffffffff
		! movq xmm3, rax
		! pshufd xmm3, xmm3, $44 ;$00000000 | $ffffffff | $00000000 | $ffffffff
		! pshufd xmm2, xmm2, 1 ;ryy | ryy | ryy | byy
		! pand xmm2, xmm3 ;0 | ryy | 0 | byy
		
		! mov eax, $ffffffff
		! movd xmm3, eax
		! pand xmm1, xmm3 ;0 | 0 | 0 | gyy
		! pslldq xmm1, 4 ;0 | 0 | gyy | 00
		
		! por xmm1, xmm2 ;0 | ryy | gyy | byy
		
		! paddd xmm1, xmm10 ;y | ryy + y | gyy + y | byy + y
		
		! packusdw xmm1, xmm1 ;32 - > 16
		! packuswb xmm1, xmm1 ;16 - > 8
		! movd [rcx + r8 * 4], xmm1 ;pokel
		! inc r8
		! cmp r8, [p.v_stop]
		! jb Tint_saut_01
		
		! mov rax, [p.v_m] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		! movdqu xmm6, [rax + 200]
		! movdqu xmm7, [rax + 216]
		! movdqu xmm8, [rax + 232]
		! movdqu xmm9, [rax + 248]
		! movdqu xmm10, [rax + 264]
		! movdqu xmm11, [rax + 280]
		! movdqu xmm12, [rax + 296]
		! movdqu xmm13, [rax + 312]
		! movdqu xmm14, [rax + 328]
		! movdqu xmm15, [rax + 344]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	Procedure Tint_mask_thread(i) 
		
		Protected start, stop, p, c.l, s.l, d.f, angle.f, s2.l, m.q
		p = @param()
		
		start = (( param(3) * param(4) ) / param(5)) * i
		stop = (( param(3) * param(4) ) / param(5)) * ( i + 1 )
		If i = param(5) - 1
			If stop < (param(3) * param(4)) : stop = param(3) * param(4) : EndIf
		EndIf
		
		angle = (3.14 * param(6)) / 180
		c = Cos(angle) * 256
		s = Sin(angle) * 256
		s2 = - s
		d = 1 / 100
		
		Protected Dim Reg_memory.q(13 * 8 + 16 * 16 ) ;(6 registes 64bits) + (4 registes 128bits)
		m = @reg_memory()							  ;sauvegarde des registes
		! mov rax, [p.v_m]
		! mov [rax + 000], rbx
		! mov [rax + 008], rcx
		! mov [rax + 016], rdx
		! mov [rax + 024], rdi
		! mov [rax + 032], rsi
		! mov [rax + 040], r8
		! mov [rax + 048], r9
		! mov [rax + 054], r10
		! mov [rax + 064], r11
		! mov [rax + 072], r12
		! mov [rax + 080], r13
		! mov [rax + 088], r14
		! mov [rax + 096], r15
		! movdqu [rax + 104], xmm0
		! movdqu [rax + 120], xmm1
		! movdqu [rax + 136], xmm2
		! movdqu [rax + 152], xmm3
		! movdqu [rax + 168], xmm4
		! movdqu [rax + 184], xmm5
		! movdqu [rax + 200], xmm6
		! movdqu [rax + 216], xmm7
		! movdqu [rax + 232], xmm8
		! movdqu [rax + 248], xmm9
		! movdqu [rax + 264], xmm10
		! movdqu [rax + 280], xmm11
		! movdqu [rax + 296], xmm12
		! movdqu [rax + 312], xmm13
		! movdqu [rax + 328], xmm14
		! movdqu [rax + 344], xmm15
		
		! movd xmm4, [p.v_d]
		! pshufd xmm4, xmm4, 0 ;d | d | d | d
		
		! mov rax, $0046ffc5fff5 ;0 | 70 | - 59 | - 11
		! mov rbx, $0000ffffffff
		! movq xmm5, rax
		! movq xmm0, rbx
		! punpcklwd xmm5, xmm0 ;16 - > 32 bits
		
		! mov rax, $ffe2ffc50059 ;0 | - 30 | - 59 | 89
		! mov rbx, $ffffffff0000
		! movq xmm6, rax
		! movq xmm0, rbx
		! punpcklwd xmm6, xmm0 ;16 - > 32
		
		! mov rax, $001e003b000b ;0 | 30 | 59 | 11
		! movq xmm7, rax
		! pxor xmm0, xmm0
		! punpcklwd xmm7, xmm0 ;16 - > 32 
		
		! mov eax, [p.v_c]
		! mov ebx, [p.v_s]
		! shl rbx, 32
		! or rax, rbx
		! movq xmm8, rax ;0 | 0 | sin | cos
		! pslldq xmm8, 8
		
		! mov eax, [p.v_s2]
		! mov ebx, [p.v_c]
		! shl rbx, 32
		! or rax, rbx
		! movq xmm9, rax ;0 | 0 | cos | - sin
		! por xmm8, xmm9
		
		! mov eax, $ffffffcd ;- 51
		! movd xmm9, eax
		! mov eax, $ffffffed ;- 19
		! movd xmm10, eax
		! pslldq xmm10, 8
		! por xmm9, xmm10
		
		! mov rcx, [p.v_p]
		! mov rdx, [rcx + 00] ;source
		! mov rbx, [rcx + 08] ;cible
		! mov rcx, [rcx + 16] ;mask
		
		! mov r8, [p.v_start]
		! Tint_mask_saut_01 : 
		
		! movd xmm1, [rdx + r8 * 4] ;peekl
		! punpcklbw xmm1, xmm0 ;08 > 16 
		! punpcklwd xmm1, xmm0 ;16 > 32
		! movdqu xmm2, xmm1
		! movdqu xmm3, xmm1
		
		! pmulld xmm1, xmm5 ;70 * r | - 59 * g | - 11 * b
		! pmulld xmm2, xmm6 ;- 30 * r | - 59 * g | 89 * b
		! pmulld xmm3, xmm7 ;30 * r | 59 * g | 11 * b
		! phaddd xmm1, xmm1 ;0 + (70 * r) | ( - 59 * g) + ( - 11 * b)
		! phaddd xmm2, xmm2
		! phaddd xmm3, xmm3
		! phaddd xmm1, xmm1 ;0 + (70 * r) + ( - 59 * g) + ( - 11 * b)
		! phaddd xmm2, xmm2
		! phaddd xmm3, xmm3
		
		! punpckldq xmm1, xmm2 ;by | ry | by | ry
		! pslldq xmm1, 4 ;ry | by | ry | 0
		! mov eax, $ffff
		! movd xmm2, eax
		! pand xmm3, xmm2
		! por xmm1, xmm3 ;;ry | by | ry | y
		
		! cvtdq2ps xmm1, xmm1
		! mulps xmm1, xmm4
		! cvtps2dq xmm1, xmm1 ;ry * d | by * d | ry * d | y * d
		;RY = ( 70 * r - 59 * g - 11 * b ) * d
		;BY = ( - 30 * r - 59 * g + 89 * b ) * d
		;Y = ( 30 * r + 59 * g + 11 * b ) * d
		
		! movdqu xmm10, xmm1
		! pshufd xmm10, xmm10, 0 ;y | y | y | y
		! psrldq xmm1, 4 ;0 | ry * d | by * d | ry * d
		! movdqu xmm2, xmm1
		
		! punpckldq xmm1, xmm1 ;by | ry | by | ry
		
		! pmulld xmm1, xmm8 ;( S * BY + C * RY ) | ( C * BY - S * RY )
		! phaddd xmm1, xmm1
		! psrad xmm1, 8 ;? | ? | byy | ryy
		! movq xmm2, xmm1
		;RYY = ( S * BY + C * RY ) >> 8;
		;BYY = ( C * BY - S * RY ) >> 8;
		
		! pmulld xmm1, xmm9
		! phaddd xmm1, xmm1
		! cvtdq2ps xmm1, xmm1
		! mulps xmm1, xmm4
		! cvtps2dq xmm1, xmm1 ;xmm1 = GYY = ( - 51 * RYY - 19 * BYY ) * d
		
		! mov rax, $ffffffff
		! movq xmm3, rax
		! pshufd xmm3, xmm3, $44 ;$00000000 | $ffffffff | $00000000 | $ffffffff
		! pshufd xmm2, xmm2, 1 ;ryy | ryy | ryy | byy
		! pand xmm2, xmm3 ;0 | ryy | 0 | byy
		
		! mov eax, $ffffffff
		! movd xmm3, eax
		! pand xmm1, xmm3 ;0 | 0 | 0 | gyy
		! pslldq xmm1, 4 ;0 | 0 | gyy | 00
		
		! por xmm1, xmm2 ;0 | ryy | gyy | byy
		
		! paddd xmm1, xmm10 ;y | ryy + y | gyy + y | byy + y
		
		! packusdw xmm1, xmm1 ;32 - > 16
		! packuswb xmm1, xmm1 ;16 - > 8
		
		
		! movd r10d, xmm1 ;calcul du mask
		! mov r11d, [rcx + r8 * 4] ;mask
		! and r10d, r11d ;modification dans le mask
		! xor r11d, $ffffffff
		! mov r12d, [rdx + r8 * 4] ;source
		! and r12d, r11d
		! or r12d, r10d ;ajout de la partie hors du mask
		;! mov [rdi], r12d
		
		! mov [rbx + r8 * 4], r12d;xmm1 ;pokel
		! inc r8
		! cmp r8, [p.v_stop]
		! jb Tint_mask_saut_01
		
		! mov rax, [p.v_m] ;restaurtion des registres
		! mov rbx, [rax + 000]
		! mov rcx, [rax + 008]
		! mov rdx, [rax + 016]
		! mov rdi, [rax + 024]
		! mov rsi, [rax + 032]
		! mov r8, [rax + 040]
		! mov r9, [rax + 048]
		! mov r10, [rax + 056]
		! mov r11, [rax + 064]
		! mov r12, [rax + 072]
		! mov r13, [rax + 080]
		! mov r14, [rax + 088]
		! mov r15, [rax + 096]
		! movdqu xmm0, [rax + 104]
		! movdqu xmm1, [rax + 120]
		! movdqu xmm2, [rax + 136]
		! movdqu xmm3, [rax + 152]
		! movdqu xmm4, [rax + 168]
		! movdqu xmm5, [rax + 184]
		! movdqu xmm6, [rax + 200]
		! movdqu xmm7, [rax + 216]
		! movdqu xmm8, [rax + 232]
		! movdqu xmm9, [rax + 248]
		! movdqu xmm10, [rax + 264]
		! movdqu xmm11, [rax + 280]
		! movdqu xmm12, [rax + 296]
		! movdqu xmm13, [rax + 312]
		! movdqu xmm14, [rax + 328]
		! movdqu xmm15, [rax + 344]
		FreeArray(Reg_memory())
		
	EndProcedure
	
	
EndModule

; IDE Options = PureBasic 6.00 Beta 8 (Windows - x64)
; CursorPosition = 16
; Folding = DAAAAAg
; Optimizer
; EnableAsm
; EnableThread
; EnableXP
; DPIAware
; CPU = 5
; Compiler = PureBasic 6.00 Beta 8 (Windows - x64)