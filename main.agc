/// Known problems:
///
/// Face culling needs improvement. At the moment objects must use SetObjectCullMode(ob, 0). However, shadows seem to be behaving OK.
/// OBJ export needs improving. Files work in 3D editors but when loaded into AGK they seem to be borked.

#include "polygon.agc"

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle("Tabletop")
SetWindowSize(1280, 720, 0)
SetWindowAllowResize( 1 ) // allow the user to resize the window

// set display properties
SetVirtualResolution(1920, 1080) // doesn't have to match the window
SetOrientationAllowed( 1, 1, 1, 1 ) // allow both portrait and landscape on mobile devices
SetSyncRate(30, 0 ) // 30fps instead of 60 to save battery
SetVSync(1)
SetScissor(0, 0, 0, 0) // use the maximum available screen space, no black borders
UseNewDefaultFonts(1) // since version 2.0.22 we can use nicer default fonts
SetAmbientColor(63, 63, 63)
SetAntialiasMode(1)
SetGenerateMipmaps(1)
SetShadowMappingMode(2)
SetShadowMapSize(1024, 1024)
SetShadowSmoothing(0)

local points as PointF[]
local faces as Face[]

SetCameraPosition(1, 0, 25, -100)
SetCameraLookAt(1, 0, 0, 0, 0)

chessImage = LoadImage("chess.jpg")
marbleImage = LoadImage("marble.png")
marbleNormalImage = LoadImage("marble_NORM.png")
baseImage = LoadImage("spy.png")
texture = FlattenImage(baseImage)

points = DouglasPeuckerReduction(CalculateHull(baseImage, 256, 1), 0.01)
faces = Triangulate(points)

ob = CreateCutoutObject(points, faces, 0.015)
SetObjectImage(ob, texture, 0)
SetObjectScale(ob, 50, 50, 50)
SetObjectRotation(ob, 180, 0, 0)
SetObjectCullMode(ob, 0)
SetObjectPosition(ob, 0, 0, 0)
SetObjectCastShadow(ob, 1)

base = CreateObjectCylinder(0.025, Abs(GetObjectSizeMinX(ob)) + GetObjectSizeMaxX(ob), 32)
SetObjectimage(base, marbleImage, 0)
SetObjectNormalMap(base, marbleNormalImage)
SetObjectPosition(base, GetObjectX(ob), GetObjectY(ob) - GetObjectSizeMinY(ob), GetObjectZ(ob))
SetObjectCastShadow(base, 1)
FixObjectToObject(base, ob)

board = CreateObjectPlane(512, 512)
SetObjectRotation(board, 90, 0, 0)
SetObjectPosition(board, 0, GetObjectY(ob) - 22, 0)
SetObjectImage(board, chessImage, 0)
SetObjectReceiveShadow(board, 1)

do
	
	RotateObjectLocalY(ob, 1)
    Print("Triangles: " + Str((faces.Length * 2) + (points.Length * 2)))
    Sync()
loop

function CreateCutoutObject(points ref as PointF[], faces ref as Face[], thickness as float)
	
	local tv as Vector3
	numVerticies = points.Length + 1
	numFaces = faces.Length + 1
	numIndicies = numFaces * 3
	numExtendedIndices = numVerticies * 2 * 3
	blockSize = (3 + 2 + 3) * 4
	thick# = thickness / 2.0
	
	vString$ = ""
	vtString$ = ""
	vnString$ = ""
	fString$ = ""

	mem = CreateMemblock((numVerticies * 2 * blockSize) + (numIndicies * 2 * 4) + (numExtendedIndices * 4) + 60)

	SetMemblockInt(mem, 0, numVerticies * 2)
	SetMemblockInt(mem, 4, numIndicies * 2 + numExtendedIndices)
	SetMemblockInt(mem, 8, 3)
	SetMemblockInt(mem, 12, blockSize)
	
	SetMemblockByte(mem, 24, 0) // Data type
	SetMemblockByte(mem, 25, 3) // Component Count
	SetMemblockByte(mem, 26, 0) // Normalize flag
	SetMemblockByte(mem, 27, 12) // String length
	SetMemblockString(mem, 28, "position") // String
	
	SetMemblockByte(mem, 40, 0) // Data type
	SetMemblockByte(mem, 41, 2) // Component Count
	SetMemblockByte(mem, 42, 0) // Normalize flag
	SetMemblockByte(mem, 43, 4) // String length
	SetMemblockString(mem, 44, "uv") // String
	
	SetMemblockByte(mem, 48, 0) // Data type
	SetMemblockByte(mem, 49, 3) // Component Count
	SetMemblockByte(mem, 50, 0) // Normalize flag
	SetMemblockByte(mem, 51, 8) // String length
	SetMemblockString(mem, 52, "normal") // String
	
	offset = 60
	SetMemblockInt(mem, 16, offset)
	
	for i = 0 to points.Length
		index = offset + (i * blockSize)
		SetMemblockFloat(mem, index, points[i].X)
		SetMemblockFloat(mem, index + 4, points[i].Y)
		SetMemblockFloat(mem, index + 8, -thick#)
		vString$ = vString$ + "v " + Str(points[i].X) + " " + Str(points[i].Y) + " " + Str(-thick#) + Chr(13) + chr(10)
		SetMemblockFloat(mem, index + 12, points[i].U)
		SetMemblockFloat(mem, index + 16, points[i].V)
		vtString$ = vtString$ + "vt " + Str(points[i].U) + " " + Str(points[i].V) + Chr(13) + chr(10)
		tv = NormalizeVector3(points[i].U - 0.5, points[i].V - 0.5, -0.5)
		SetMemblockFloat(mem, index + 20, tv.X)
		SetMemblockFloat(mem, index + 24, tv.Y)
		SetMemblockFloat(mem, index + 28, tv.Z)
		vnString$ = vnString$ + "vn " + Str(tv.X) + " " + Str(tv.Y) + " " + Str(tv.Z) + Chr(13) + chr(10)
	next i
	
	offset = offset + (numVerticies * blockSize)
	for i = 0 to points.Length
		index = offset + (i * blockSize)
		SetMemblockFloat(mem, index, points[i].X)
		SetMemblockFloat(mem, index + 4, points[i].Y)
		SetMemblockFloat(mem, index + 8, thick#)
		vString$ = vString$ + "v " + Str(points[i].X) + " " + Str(points[i].Y) + " " + Str(thick#) + Chr(13) + chr(10)
		SetMemblockFloat(mem, index + 12, points[i].U)
		SetMemblockFloat(mem, index + 16, points[i].V)
		vtString$ = vtString$ + "vt " + Str(points[i].U) + " " + Str(points[i].V) + Chr(13) + chr(10)
		tv = NormalizeVector3(points[i].U - 0.5, points[i].V - 0.5, 0.5)
		SetMemblockFloat(mem, index + 20, tv.X)
		SetMemblockFloat(mem, index + 24, tv.Y)
		SetMemblockFloat(mem, index + 28, tv.Z)
		vnString$ = vnString$ + "vn " + Str(tv.X) + " " + Str(tv.Y) + " " + Str(tv.Z) + Chr(13) + chr(10)
	next i
	
	offset = offset + (numVerticies * blockSize)
	SetMemblockInt(mem, 20, offset)
	
	fString$ = fString$ + "g object" + Chr(13) + Chr(10) + "usemtl material" + Chr(13) + Chr(10)
	
	for i = 0 to faces.Length
		index = offset + (i * 12)
		SetmemblockInt(mem, index, faces[i].Vertex[2].ID + 0)
		SetmemblockInt(mem, index + 4, faces[i].Vertex[1].ID + 0)
		SetmemblockInt(mem, index + 8, faces[i].Vertex[0].ID + 0)

		fString$ = fString$ + "f " + Str(faces[i].Vertex[0].ID + 1) + " " + Str(faces[i].Vertex[1].ID + 1) + " " + Str(faces[i].Vertex[2].ID + 1) + Chr(13) + Chr(10)
	next i
	
	offset = offset + (numIndicies * 4)
	for i = 0 to faces.Length
		index = offset + (i * 12)
		v = faces[i].Vertex.Length
		SetmemblockInt(mem, index, faces[i].Vertex[0].ID + numVerticies)
		SetmemblockInt(mem, index + 4, faces[i].Vertex[1].ID + numVerticies)
		SetmemblockInt(mem, index + 8, faces[i].Vertex[2].ID + numVerticies)
		fString$ = fString$ + "f " + Str(faces[i].Vertex[0].ID + 1 + numVerticies) + " " + Str(faces[i].Vertex[1].ID + 1 + numVerticies) + " " + Str(faces[i].Vertex[2].ID + 1 + numVerticies) + Chr(13) + Chr(10)
	next i
	
	offset = offset + (numIndicies * 4)
	
	// Extended indices
	for i = 0 to points.Length
		p1 = i
		p2 = Mod(i + 1, points.Length + 1)
		index = offset + (i * 12)
		SetmemblockInt(mem, index, p1 + 0)
		SetmemblockInt(mem, index + 4, p2 + 0)
		SetmemblockInt(mem, index + 8, p2 + numVerticies)
		fString$ = fString$ + "f " + Str(p1 + 0 + 1) + " " + Str(p2 + 0 + 1) + " " + Str(p2 + numVerticies + 1) + Chr(13) + Chr(10)
	next i
	
	offset = offset + (numVerticies * 3 * 4)
	for i = 0 to points.Length
		p1 = i
		p2 = Mod(i + 1, points.Length + 1)
		index = offset + (i * 12)
		SetmemblockInt(mem, index, p2 + numVerticies)
		SetmemblockInt(mem, index + 4, p1 + numVerticies)
		SetmemblockInt(mem, index + 8, p1 + 0)
		fString$ = fString$ + "f " + Str(p2 + numVerticies + 1) + " " + Str(p1 + numVerticies + 1) + " " + Str(p1 + 0 + 1) + Chr(13) + Chr(10)
	next i
		
	ob = CreateObjectFromMeshMemblock(mem)
		
	DeleteMemblock(mem)
	
	f = OpenToWrite("output.obj")
	WriteLine(f, vString$)
	WriteLine(f, vtString$)
	WriteLine(f, vnString$)
	WriteLine(f, fString$)
	CloseFile(f)
	
endfunction ob

function FlattenImage(img as integer)
	
	rw = GetVirtualWidth()
	rh = GetVirtualHeight()
	
	iw = GetImageWidth(img)
	ih = GetImageHeight(img)
	
	r = CreateRenderImage(iw, ih, 0, 0)
	SetImageMagFilter(r, 0)
	SetImageMinFilter(r, 0)
	
	SetRenderToImage(r, 0)
	SetVirtualResolution(iw, ih)
	
	s = CreateSprite(img)
	SetSpritePositionByOffset(s, iw / 2, ih / 2)
	DrawSprite(s)
	DeleteSprite(s)
	
	SetRenderToScreen()
	SetVirtualResolution(rw, rh)
	
	mem = CreateMemblockFromImage(r)
	
	for y = 0 to ih -1
		for x = 0 to iw -1
			
			i = (y * iw) + x
			alpha = GetMemblockByte(mem, (i * 4) + 3 + 12)
			
			if alpha = 0
				SetMemblockByte(mem, (i * 4) + 12, 255)
				SetMemblockByte(mem, (i * 4) + 1 + 12, 255)
				SetMemblockByte(mem, (i * 4) + 2 + 12, 255)
				SetMemblockByte(mem, (i * 4) + 3 + 12, 255)
			endif
			
		next x
	next y
	
	DeleteImage(r)
	r = CreateImageFromMemblock(mem)
	
endfunction r

function CalculateHull(img as integer, resolution as integer, erodeCount as integer)
	
	fres# = resolution
	hres# = fres# / 2.0
	
	rw = GetVirtualWidth()
	rh = GetVirtualHeight()
	
	iw# = GetImageWidth(img)
	ih# = GetImageHeight(img)
	
	if iw# > ih#
		m# = iw#
		uscale# = 1.0
		vscale# = iw# / ih#
	else
		m# = ih#
		uscale# = ih# / iw#
		vscale# = 1.0
	endif
	
	r = CreateRenderImage(resolution, resolution, 0, 0)
	SetImageMagFilter(r, 0)
	SetImageMinFilter(r, 0)
	
	SetRenderToImage(r, 0)
	SetVirtualResolution(m#, m#)
	
	s = CreateSprite(img)
	SetSpritePositionByOffset(s, m# / 2.0, m# / 2.0)
	DrawSprite(s)
	DeleteSprite(s)
	
	SetRenderToScreen()
	SetVirtualResolution(rw, rh)
	
	mem = CreateMemblockFromImage(r)
	mem2 = CreateMemblockFromImage(r)
	
	sx = -1
	sy = -1
	alpha = 0
	pcount = 0
	
	local state as integer[]
	local points as PointF[]
	
	// Erode edge
	for ec = 0 to erodeCount
		
		for y = 0 to resolution - 1
			for x = 0 to resolution - 1
				
				i = (y * resolution) + x
				alpha = GetMemblockByte(mem2, (i * 4) + 3 + 12)
				
				if alpha = 0 // Pixel is invisible
					
					c = 0
					for iy = MaxInteger(y - 1, 0) to MinInteger(y + 1, resolution - 1)
						for ix = MaxInteger(x - 1, 0) to MinInteger(x + 1, resolution - 1)
							
							if iy <> y or ix <> x
								ii = (iy * resolution) + ix
								ialpha = GetMemblockByte(mem2, (ii * 4) + 3 + 12)
								if ialpha > 0
									inc c
								endif
							endif
							
						next ix
					next iy
					
					if c > 0 // One or more adjacent visible pixels
						SetMemblockByte(mem, (i * 4) + 12, 255)
						SetMemblockByte(mem, (i * 4) + 1 + 12, 255)
						SetMemblockByte(mem, (i * 4) + 2 + 12, 255)
						SetMemblockByte(mem, (i * 4) + 3 + 12, 255)
					endif
					
				endif
				
			next x
		next y
	
		CopyMemblock(mem, mem2, 0, 0, GetMemblockSize(mem))
	
	next ec
	
	// Edge detection
	for y = 0 to resolution -1
		for x = 0 to resolution -1
			
			i = (y * resolution) + x
			alpha = GetMemblockByte(mem, (i * 4) + 3 + 12)
			
			if alpha = 0 or y = 0 or x = 0 or y = resolution - 1 or x = resolution - 1 // Pixel is invisible
								
				c = 0
				for iy = MaxInteger(y - 1, 0) to MinInteger(y + 1, resolution - 1)
					for ix = MaxInteger(x - 1, 0) to MinInteger(x + 1, resolution - 1)
						
						if iy <> y or ix <> x
							ii = (iy * resolution) + ix
							ialpha = GetMemblockByte(mem, (ii * 4) + 3 + 12)
							if ialpha > 0
								inc c
							endif
						endif
						
					next ix
				next iy
				
				if c = 0 // No visible pixels adjacent
					state.Insert(0)
				else // One or more adjacent visible pixels
					state.Insert(1)
					inc pcount
					if sy = -1 // Record top left pixel
						sy = y
						sx = x
					endif
				endif
			else // Visible pixel
				state.Insert(0)
			endif
			
		next x
	next y
		
	DeleteMemblock(mem)
	DeleteMemblock(mem2)
	DeleteImage(r)
	
	// Navigate the outline to generate a list of pixels
	lastAngle = 0
	c = 0
	nx = sx
	ny = sy
	repeat
		
		found = 0
		i = (ny * resolution) + nx
		
		if i >= 0 and i < (resolution * resolution)
			
			state[i] = 2
			nxf# = nx
			nuf# = nxf# / fres#
			nxf# = (nxf# - hres#) / fres#
			nyf# = ny
			nvf# = nyf# / fres#
			nyf# = (nyf# - hres#) / fres#
			
			nuf# = (nxf# * uscale#) + 0.5
			nvf# = (nyf# * vscale#) + 0.5
			
			points.Insert(CreatePointF(c, nxf#, nyf#, nuf#, nvf#))
			
			inc c
			dec pcount
				
			for angle = 0 to 315 step 45

				tangle = Mod(lastAngle - 180 + angle, 360)
				ix = Round(Sin(tangle)) + nx
				iy = Round(-Cos(tangle)) + ny
				
				g = GetGridCell(state, ix, iy, resolution, resolution)
				
				if g = 1
					nx = ix
					ny = iy
					lastAngle = tangle
					found = 1
					exit
				endif
						
			next angle
		
		endif
			
	until pcount = 0 or found = 0
	
endfunction points

function GetGridCell(grid ref as integer[], x, y, width, height)
	
	i = (y * width) + x
	
	if i < 0 or i >= (width * height)
		exitfunction 0
	else
		exitfunction grid[i]
	endif
	
endfunction 0

function MaxInteger(a, b)
	
	if a > b
		exitfunction a
	endif
	
endfunction b

function MinInteger(a, b)
	
	if a < b
		exitfunction a
	endif
	
endfunction b
