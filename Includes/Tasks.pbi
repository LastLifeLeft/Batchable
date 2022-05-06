Module Tasks
	
	Task(#Task_AlphaThreshold)\Name = "Alpha Threshold"
	Task(#Task_AlphaThreshold)\Description = "Remove gradation to alpha transparency according to a given value."
	Task(#Task_AlphaThreshold)\Type = MainWindow::#TaskType_Colors
	Task(#Task_AlphaThreshold)\IconID = ImageID(CatchImage(#PB_Any, ?Threshold))
	
	Task(#Task_ChannelSwap)\Name = "Channel Swap"
	Task(#Task_ChannelSwap)\Description = "Change each color channels assignation."
	Task(#Task_ChannelSwap)\Type = MainWindow::#TaskType_Colors
	Task(#Task_ChannelSwap)\IconID = ImageID(CatchImage(#PB_Any, ?ChannelSwap))
	
	Task(#Task_ChannelDisplacement)\Name = "Channel Displacement"
	Task(#Task_ChannelDisplacement)\Description = "Move around each color channel individually."
	Task(#Task_ChannelDisplacement)\Type = MainWindow::#TaskType_Colors
	Task(#Task_ChannelDisplacement)\IconID = ImageID(CatchImage(#PB_Any, ?ChannelDisplacement))
	
	Task(#Task_InvertColor)\Name = "Invert Color"
	Task(#Task_InvertColor)\Description = "Reverse the colors, black becomes white, white becomes black."
	Task(#Task_InvertColor)\Type = MainWindow::#TaskType_Colors
	Task(#Task_InvertColor)\IconID = ImageID(CatchImage(#PB_Any, ?Invertcolor))
	
	Task(#Task_BlackWhite)\Name = "Black & White"
	Task(#Task_BlackWhite)\Description = "Convert all colors to black and white (greyscale)."
	Task(#Task_BlackWhite)\Type = MainWindow::#TaskType_Colors
	Task(#Task_BlackWhite)\IconID = ImageID(CatchImage(#PB_Any, ?BlackAndWhite))
	
	Task(#Task_ColorBalancing)\Name = "Color Balance"
	Task(#Task_ColorBalancing)\Description = "Change the global adjustment of the intensities of the colors."
	Task(#Task_ColorBalancing)\Type = MainWindow::#TaskType_Colors
	Task(#Task_ColorBalancing)\IconID = ImageID(CatchImage(#PB_Any, ?ColorBalance))
	
	Task(#Task_Posterization)\Name = "Posterization"
	Task(#Task_Posterization)\Description = "Reduce the range of colors used to fewer tones."
	Task(#Task_Posterization)\Type = MainWindow::#TaskType_Colors
	Task(#Task_Posterization)\IconID = ImageID(CatchImage(#PB_Any, ?Posterization))
	
	Task(#Task_Outline)\Name = "Outline"
	Task(#Task_Outline)\Description = "Add an outline around objects."
	Task(#Task_Outline)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Outline)\IconID = ImageID(CatchImage(#PB_Any, ?Outline))
	
	Task(#Task_TrimImage)\Name = "Trim Border"
	Task(#Task_TrimImage)\Description = "Remove the transparent pixels around the images."
	Task(#Task_TrimImage)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_TrimImage)\IconID = ImageID(CatchImage(#PB_Any, ?Trim))
	
	Task(#Task_Resize)\Name = "Resize"
	Task(#Task_Resize)\Description = "Resize to target size using various algorithms."
	Task(#Task_Resize)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Resize)\IconID = ImageID(CatchImage(#PB_Any, ?Resize))
	
	Task(#Task_Blur)\Name = "Blur"
	Task(#Task_Blur)\Description = "Apply a gaussian blur on the images."
	Task(#Task_Blur)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Blur)\IconID = ImageID(CatchImage(#PB_Any, ?Blur))
	
	Task(#Task_Watermark)\Name = "Watermark"
	Task(#Task_Watermark)\Description = "Overlay the images with a text or another image."
	Task(#Task_Watermark)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Watermark)\IconID = ImageID(CatchImage(#PB_Any, ?Watermark))
	
	Task(#Task_Rotsprite)\Name = "Rotsprite"
	Task(#Task_Rotsprite)\Description = "Rotates images using the Rotsprite algorithm by Xenowhirl."
	Task(#Task_Rotsprite)\Type = MainWindow::#TaskType_PixelArt
	Task(#Task_Rotsprite)\IconID = ImageID(CatchImage(#PB_Any, ?RotSprite))
	
	Task(#Task_PixelartUpscale)\Name = "Pixel-art upscale"
	Task(#Task_PixelartUpscale)\Description = "Upscale sprites using various algorithms."
	Task(#Task_PixelartUpscale)\Type = MainWindow::#TaskType_PixelArt
	Task(#Task_PixelartUpscale)\IconID = ImageID(CatchImage(#PB_Any, ?PixelUpscale))
	
	Task(#Task_SaveGif)\Name = "Save as gif"
	Task(#Task_SaveGif)\Description = "Merge all the images in a single gif file."
	Task(#Task_SaveGif)\Type = MainWindow::#TaskType_Other
	Task(#Task_SaveGif)\IconID = ImageID(CatchImage(#PB_Any, ?Gif))
	
	Task(#Task_Save)\Name = "Save"
	Task(#Task_Save)\Description = "Save the results on the disk."
	Task(#Task_Save)\Type = MainWindow::#TaskType_Other
	Task(#Task_Save)\IconID = ImageID(CatchImage(#PB_Any, ?Save))

	DataSection
		BlackAndWhite:
		IncludeBinary "..\Media\Tinified\Black & White.png"
		
		Blur:
		IncludeBinary "..\Media\Tinified\Blur.png"
		
		ChannelDisplacement:
		IncludeBinary "..\Media\Tinified\Channel Displacement.png"
		
		ChannelSwap:
		IncludeBinary "..\Media\Tinified\Channel swap.png"
		
		ColorBalance:
		IncludeBinary "..\Media\Tinified\Color Balance.png"
		
		Gif:
		IncludeBinary "..\Media\Tinified\Gif.png"
		
		Invertcolor:
		IncludeBinary "..\Media\Tinified\Invert color.png"
		
		Outline:
		IncludeBinary "..\Media\Tinified\Outline.png"
		
		PixelUpscale:
		IncludeBinary "..\Media\Tinified\Pixel Upscale.png"
		
		Posterization:
		IncludeBinary "..\Media\Tinified\Posterization.png"
		
		Resize:
		IncludeBinary "..\Media\Tinified\Resize.png"
		
		RotSprite:
		IncludeBinary "..\Media\Tinified\RotSprite.png"
		
		Save:
		IncludeBinary "..\Media\Tinified\Save.png"
		
		Threshold:
		IncludeBinary "..\Media\Tinified\Threshold.png"
		
		Trim:
		IncludeBinary "..\Media\Tinified\Trim.png"
		
		Watermark:
		IncludeBinary "..\Media\Tinified\Watermark.png"
		
	
	EndDataSection
EndModule
; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 18
; Folding = -
; EnableXP