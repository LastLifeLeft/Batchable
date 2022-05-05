Module Tasks
	
	Task(#Task_AlphaThreshold)\Name = "Alpha Threshold"
	Task(#Task_AlphaThreshold)\Description = "Remove gradation to alpha transparency according to a given value."
	Task(#Task_AlphaThreshold)\Type = MainWindow::#TaskType_Colors
	Task(#Task_AlphaThreshold)\IconID = 0
	
	Task(#Task_ChannelSwap)\Name = "Channel Swap"
	Task(#Task_ChannelSwap)\Description = "Change each color channels assignation."
	Task(#Task_ChannelSwap)\Type = MainWindow::#TaskType_Colors
	Task(#Task_ChannelSwap)\IconID = 0
	
	Task(#Task_ChannelDisplacement)\Name = "Channel Displacement"
	Task(#Task_ChannelDisplacement)\Description = "Displace each color channel individually."
	Task(#Task_ChannelDisplacement)\Type = MainWindow::#TaskType_Colors
	Task(#Task_ChannelDisplacement)\IconID = 0
	
	Task(#Task_InvertColor)\Name = "Invert Color"
	Task(#Task_InvertColor)\Description = "reverse the colors, black becomes white, white becomes black."
	Task(#Task_InvertColor)\Type = MainWindow::#TaskType_Colors
	Task(#Task_InvertColor)\IconID = 0
	
	Task(#Task_BlackWhite)\Name = "Black & White"
	Task(#Task_BlackWhite)\Description = "Convert all colors to black and white (greyscale)."
	Task(#Task_BlackWhite)\Type = MainWindow::#TaskType_Colors
	Task(#Task_BlackWhite)\IconID = 0
	
	Task(#Task_ColorBalancing)\Name = "Color Balancing"
	Task(#Task_ColorBalancing)\Description = "Change the global adjustment of the intensities of the colors. Et là je prolonge la phrase pour voir comment ça fait avec un wrap..."
	Task(#Task_ColorBalancing)\Type = MainWindow::#TaskType_Colors
	Task(#Task_ColorBalancing)\IconID = 0
	
	Task(#Task_Posterization)\Name = "Posterization"
	Task(#Task_Posterization)\Description = "Reduce the range of colors used to fewer tones."
	Task(#Task_Posterization)\Type = MainWindow::#TaskType_Colors
	Task(#Task_Posterization)\IconID = 0
	
	Task(#Task_Outline)\Name = "Outline"
	Task(#Task_Outline)\Description = "Add an outline around objects."
	Task(#Task_Outline)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Outline)\IconID = 0
	
	Task(#Task_TrimImage)\Name = "TrimImage"
	Task(#Task_TrimImage)\Description = "Remove the transparent pixels around the images."
	Task(#Task_TrimImage)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_TrimImage)\IconID = 0
	
	Task(#Task_Resize)\Name = "Resize"
	Task(#Task_Resize)\Description = "Resize to target size using various algorithms."
	Task(#Task_Resize)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Resize)\IconID = 0
	
	Task(#Task_Blur)\Name = "Blur"
	Task(#Task_Blur)\Description = "Apply a gaussian blur on the images."
	Task(#Task_Blur)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Blur)\IconID = 0
	
	Task(#Task_Watermark)\Name = "Watermark"
	Task(#Task_Watermark)\Description = "Overlay the images with a text or another image."
	Task(#Task_Watermark)\Type = MainWindow::#TaskType_Transformation
	Task(#Task_Watermark)\IconID = 0
	
	Task(#Task_Rotsprite)\Name = "Rotsprite"
	Task(#Task_Rotsprite)\Description = "Rotates images using the Rotsprite algorithm by Xenowhirl."
	Task(#Task_Rotsprite)\Type = MainWindow::#TaskType_PixelArt
	Task(#Task_Rotsprite)\IconID = 0
	
	Task(#Task_PixelartUpscale)\Name = "Pixel-art upscale"
	Task(#Task_PixelartUpscale)\Description = "Upscale sprites using various algorithms."
	Task(#Task_PixelartUpscale)\Type = MainWindow::#TaskType_PixelArt
	Task(#Task_PixelartUpscale)\IconID = 0
	
	Task(#Task_SaveGif)\Name = "Save as gif"
	Task(#Task_SaveGif)\Description = "Merge all the images in a single gif file."
	Task(#Task_SaveGif)\Type = MainWindow::#TaskType_Other
	Task(#Task_SaveGif)\IconID = 0
	
	Task(#Task_Save)\Name = "Save"
	Task(#Task_Save)\Description = "Save the results on the disk."
	Task(#Task_Save)\Type = MainWindow::#TaskType_Other
	Task(#Task_Save)\IconID = 0

	
EndModule
; IDE Options = PureBasic 6.00 Beta 6 (Windows - x64)
; CursorPosition = 21
; Folding = -
; EnableXP