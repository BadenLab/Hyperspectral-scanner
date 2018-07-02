#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////////////////////////////////////////////////////////////////////
/// Collector ///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
///															
/// This function collects all individual measurements in one "alldata"  
/// wave and deletes the original waves.							
///															
/////////////////////////////////////////////////////////////////////////

function Collect(DataFolder)
string DataFolder

SetDataFolder "root:"
String Folderaddress = "root:"+DataFolder
wave ScanX
wave ScanY

variable nWavelengths = 3648

SetDataFolder 'Folderaddress'

variable nScanPoints = countObjects(":",1)/2

wave wave0
duplicate wave0 Wavelength
make /n=(nWavelengths,nScanPoints) alldata = NaN

variable ww
for (ww=0;ww<nScanPoints;ww+=1)
	string currentname = "wave"+Num2Str(ww*2)
	killwaves $currentname
	currentname = "wave"+Num2Str(ww*2 + 1)
	duplicate /o $currentname currentdata		
	alldata[][ww]=currentdata[p]
	killwaves $currentname
endfor

killwaves currentdata
SetDataFolder "root:"
print "done... collected"+Num2Str(nScanPoints)+"scans"

// This is used to go linear from log-recorded data
duplicate alldata alldata2
alldata[][][]=10^alldata2[p][q][r] 
killwaves alldata2

end


/////////////////////////////////////////////////////////////////////////////////////////////////
/// Analyser ////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
///	                                                                                        
/// This requires the "alldata" and "Wavelength" waves as generated in the collector function 
/// In addition, the opsin and scan path waves must be present in external folders:		
/// root:Scanpaths/Spiral1000_30deg/ScanX (&ScanY)								
/// root:Opsins/human/Opsin_red (+green, blue, UV)									
///																				
/////////////////////////////////////////////////////////////////////////////////////////////////

function Analyse(DataFolder,Scanpath,species,display_stuff)
string DataFolder,Scanpath,species
variable display_stuff // 0 or 1

// Chromattype needs to be set to the number of different cones the animal has
variable Chromattype = 4

// How much the image is cropped from the right and left sides. This is only needed if the
// waterproof boxing is used.
variable XEdgeCrop_deg = 0
// Hack to kill interpolation edge artifact
variable extracrop_px = 4

// If set to 1, rotates the image 90 degrees right + mirrors it
variable flipflop = 0

variable PCA_uses_log_Activation = 1 // PCA done using log normalised or linear data (0,1)

variable targetrange_min = 200 // Wanted spectra from 200 nm
variable targetrange_nm = 800  // Up to 200+800 = 1000 nm

variable nOpsins = 4 // Must be 4 at current script
variable nPx = 150 // Number of pixels of reconstruction maps - if increased, get higher resolution reconstructions (which is pointless unless get higher resolution scans)
variable smoothingfactor = 10 // Point-smooth on individual spectra to rid NaNs
variable edge_compression = 0.9 

SetDataFolder "root:"

// Get ScanX and ScanY
String XAddress = "root:"+Scanpath+":ScanY"
String YAddress = "root:"+Scanpath+":ScanX"

// Get Opsins
String Opsin1Address = "root:Opsins:"+Species+":Opsin_Red"
String Opsin2Address = "root:Opsins:"+Species+":Opsin_Green"
String Opsin3Address = "root:Opsins:"+Species+":Opsin_Blue"
String Opsin4Address = "root:Opsins:"+Species+":Opsin_UV"

// Gets opsins from external opsin folder
duplicate /o $Opsin1Address Opsin1_temp
duplicate /o $Opsin2Address Opsin2_temp
duplicate /o $Opsin3Address Opsin3_temp
duplicate /o $Opsin4Address Opsin4_temp

String Folderaddress = "root:"+DataFolder
SetDataFolder $Folderaddress

// Gets scan path from external scan path folder
duplicate /o $XAddress ScanX
duplicate /o $YAddress ScanY

variable nScanPoints = Dimsize(ScanX,0)

// Find the scan radius
make /o/n=(4) MaxFind = NaN
MaxFind[0] = Wavemax(ScanX)-90
MaxFind[1] = (Wavemin(ScanX)-90)*-1
MaxFind[2] = Wavemax(ScanY)-90
MaxFind[3] = (Wavemin(ScanY)-90)*-1
Wavestats/Q MaxFind
variable ScanRadius = MaxFind[V_MaxLoc] + 1
variable nPx_per_deg =  nPx/(ScanRadius*2)*edge_compression
variable scanrange_px = nPx_per_deg*ScanRadius
variable XEdgeCrop_px=XEdgeCrop_deg*nPx_per_deg

print "Scan radius:", ScanRadius, "degrees"
print "Reconstruction at ",nPx_per_deg, "pixels per degree"
killwaves MaxFind

// Format data to 1 nm per entry
wave alldata
wave wavelength
variable nWavelengths = Dimsize(Wavelength,0)
variable ss
Duplicate/O alldata,alldata_smth

// If n points are missing, this breaks the scan into n+1 segments and duplicates the last. Basically a "trick" to rescue a scan if it dropped a spectrum at some point
// point of each segment
if (dimsize(alldata_smth,1)<nScanPoints)
	print "Warning, missing",Num2Str(nScanPoints-dimsize(alldata_smth,1)) ,"scan point(s), filling in from neighbours"
	make /o/n=(Dimsize(alldata_smth,0),nScanpoints) alldata_smth_added = 0
	
	variable nPoints_missing = nScanPoints - dimsize(alldata_smth,1)
	variable nSegments = nPoints_missing+1
	variable Segment_size = floor(dimsize(alldata_smth,1)/nSegments)
	
	for (ss=0;ss<nSegments;ss+=1) 
		alldata_smth_added[][ss*Segment_size+ss,(ss+1)*Segment_size-1+ss]=alldata_smth[p][q-ss] // write 1 segment
		alldata_smth_added[][(ss+1)*Segment_size-1+ss+1]=alldata_smth[p][q-ss-1] // fill in 1 extra point
	endfor
	
	duplicate /o alldata_smth_added alldata_smth
	killwaves alldata_smth_added		
endif

Smooth/EVEN/B smoothingfactor, alldata_smth
make /o/n=(targetrange_nm,nScanPoints) alldata_formatted = 0

// Manual resampling of the data
variable ww,aa
variable wwcounter = targetrange_min
variable nWL_avg = 0
for (ww=0;ww<nWavelengths;ww+=1)
	if (wwcounter<Wavelength[ww] && wwcounter+1>Wavelength[ww])
		nWL_avg+=1
	endif
	if (wwcounter+1<=Wavelength[ww])
		for (aa=0;aa<nWL_avg;aa+=1)
			if (wwcounter<1000)
				alldata_formatted[wwcounter-targetrange_min][]+=alldata_smth[ww-nWL_avg+aa][q]/nWL_avg		
			endif
		endfor
		wwcounter+=1
		nWL_avg = 0
	endif	
endfor

setscale x,targetrange_min,targetrange_min+targetrange_nm,"nm" alldata_formatted
killwaves alldata_smth

// Format opsins
make /o/n=(targetrange_nm) Opsin1 = Opsin1_temp[p+targetrange_min]
make /o/n=(targetrange_nm) Opsin2 = Opsin2_temp[p+targetrange_min]
make /o/n=(targetrange_nm) Opsin3 = Opsin3_temp[p+targetrange_min]
make /o/n=(targetrange_nm) Opsin4 = Opsin4_temp[p+targetrange_min]
killwaves opsin1_temp,opsin2_temp,opsin3_temp,opsin4_temp
setscale x,targetrange_min,targetrange_min+targetrange_nm,"nm" opsin1,opsin2,opsin3,opsin4

// Kills edgepixels as defined by "XEdgeCrop_deg" in the beginning
duplicate /o alldata_formatted alldata_formatted_temp
duplicate /o ScanX ScanX_temp
duplicate /o ScanX ScanY_temp
variable nScanPoints_used = 0
for (ww=0;ww<nScanPoints;ww+=1)
	if (flipflop==0)
		if (ScanX[ww]-90<ScanRadius-XEdgeCrop_deg && ScanX[ww]-90>-ScanRadius+XEdgeCrop_deg)
			ScanX_temp[nScanPoints_used]=ScanX[ww]
			ScanY_temp[nScanPoints_used]=ScanY[ww]		
			alldata_formatted_temp[][nScanPoints_used]=alldata_formatted[p][ww]		
			nScanPoints_used+=1
		endif
	else
		if (ScanY[ww]-90<ScanRadius-XEdgeCrop_deg && ScanY[ww]-90>-ScanRadius+XEdgeCrop_deg)
			ScanX_temp[nScanPoints_used]=ScanY[ww]
			ScanY_temp[nScanPoints_used]=ScanX[ww]		
			alldata_formatted_temp[][nScanPoints_used]=alldata_formatted[p][ww]		
			nScanPoints_used+=1
		endif
	endif
	
endfor
print nScanPoints_used,"/",nScanPoints, "pixels used after discarding X edge pixels"
make /o/n=(nScanPoints_used) ScanX_cropped = ScanX_temp[p]
make /o/n=(nScanPoints_used) ScanY_cropped = ScanY_temp[p]
make /o/n=(targetrange_nm,nScanPoints_used) alldata_formatted_cropped = alldata_formatted_temp[p][q]

killwaves ScanX_temp ,ScanY_temp, alldata_formatted_temp

// Set up Opsin activation arrays
make /o/n=(nScanPoints_used,nOpsins) Opsin_activation = NaN

// Set up Opsin map reconstructions
make /o/n=(nPx,nPx) reconstructionR = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionR
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionR

make /o/n=(nPx,nPx) reconstructionG = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionG
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionG

make /o/n=(nPx,nPx) reconstructionB = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionB
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionB

make /o/n=(nPx,nPx) reconstructionU = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionU
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionU

make /o/n=(nPx,nPx) luminance_channel = NaN
setscale x,-ScanRadius,ScanRadius,"deg" luminance_channel
setscale y,-ScanRadius,ScanRadius,"deg" luminance_channel

make /o/n=(nPx,nPx,targetrange_nm) full_reconstruction = NaN
setscale x,-ScanRadius,ScanRadius,"deg" full_reconstruction
setscale y,-ScanRadius,ScanRadius,"deg" full_reconstruction
setscale z,targetrange_min,targetrange_min+targetrange_nm,"nm" full_reconstruction

make /o/n=(targetrange_nm) currentwave = 0

variable ScanSpacing_min = 100
variable TargetX, TargetY, xx,yy,ii

for (ww=0;ww<nScanPoints_used;ww+=1)
	
	TargetX = ((ScanX_cropped[ww]-90)/ScanRadius) * nPx/2*edge_compression + nPx/2
	TargetY = ((ScanY_cropped[ww]-90)/ScanRadius) * -nPx/2*edge_compression + nPx/2 
	
	if (ww<nScanPoints_used-1)
		if (((ScanX_cropped[ww]-ScanX_cropped[ww+1])^2+(ScanY_cropped[ww]-ScanY_cropped[ww+1])^2)^0.5 < ScanSpacing_min)
			ScanSpacing_min = ((ScanX_cropped[ww]-ScanX_cropped[ww+1])^2+(ScanY_cropped[ww]-ScanY_cropped[ww+1])^2)^0.5
		endif
	endif
		
	currentwave=exp(alldata_formatted_cropped[p][ww])
	variable currentmin = wavemin(currentwave)
	if (Numtype(currentmin)==2)
		currentmin = 0
	endif
	currentwave[]=(NumType(currentwave[p])==2)?(currentmin):(currentwave[p])
	
	make /o/n=(targetrange_nm) current_activationwave = currentwave*opsin1
	Wavestats/Q current_activationwave
	Opsin_activation[ww][0] = V_Sum
	make /o/n=(targetrange_nm) current_activationwave = currentwave*opsin2
	Wavestats/Q current_activationwave
	Opsin_activation[ww][1] = V_Sum	
	make /o/n=(targetrange_nm) current_activationwave = currentwave*opsin3
	Wavestats/Q current_activationwave
	Opsin_activation[ww][2] = V_Sum	
	make /o/n=(targetrange_nm) current_activationwave = currentwave*opsin4
	Wavestats/Q current_activationwave
	Opsin_activation[ww][3] = V_Sum

	luminance_channel[TargetX][TargetY]=(log(Opsin_activation[ww][0])+log(Opsin_activation[ww][1])+log(Opsin_activation[ww][2])+log(Opsin_activation[ww][3])/4	)
	reconstructionR[TargetX][TargetY]=log(Opsin_activation[ww][0])
	reconstructionG[TargetX][TargetY]=log(Opsin_activation[ww][1])
	reconstructionB[TargetX][TargetY]=log(Opsin_activation[ww][2])
	reconstructionU[TargetX][TargetY]=log(Opsin_activation[ww][3])
	Multithread full_reconstruction[TargetX][TargetY][]=log(currentwave[r])
	
endfor

print "Scan-spacing: ", round(ScanSpacing_min*100)/100, "degrees"

// Interpolate the reconstructed images
duplicate /o reconstructionR reconstruction_lookup
variable interpolate_range = ceil(ScanSpacing_min*nPx_per_deg+1)
variable currentmix = 0
variable currentdistance = 0
variable shortestdistance = 0
variable nearest_nonNaN_X = 0
variable nearest_nonNaN_Y = 0
variable distance_from_center
variable ipX,ipY

for (xx=interpolate_range;xx<nPx-interpolate_range;xx+=1)
	for (yy=interpolate_range;yy<nPx-interpolate_range;yy+=1)
		distance_from_center = ((nPx/2-xx)^2+(nPx/2-yy)^2)^0.5
		if (distance_from_center<scanrange_px && xx>=XEdgeCrop_px+extracrop_px && xx<=nPx-XEdgeCrop_px-extracrop_px)
			currentmix = 0
			shortestdistance = interpolate_range*2
			for (ipX=-interpolate_range;ipX<interpolate_range+1;ipX+=1)
				for (ipY=-interpolate_range;ipY<interpolate_range+1;ipY+=1)
					if (Numtype(reconstruction_lookup[xx+ipX][yy+ipY])==2)
					else
						currentdistance = (ipX^2+ipY^2)^0.5
						if (currentdistance<shortestdistance)
							shortestdistance = currentdistance
							nearest_nonNaN_X = xx+ipX
							nearest_nonNaN_Y = yy+ipY		
						endif
					endif
				endfor
			endfor
			reconstructionR[xx][yy]=reconstructionR[nearest_nonNaN_X][nearest_nonNaN_Y]
			reconstructionG[xx][yy]=reconstructionG[nearest_nonNaN_X][nearest_nonNaN_Y]
			reconstructionB[xx][yy]=reconstructionB[nearest_nonNaN_X][nearest_nonNaN_Y]
			reconstructionU[xx][yy]=reconstructionU[nearest_nonNaN_X][nearest_nonNaN_Y]	
			luminance_channel[xx][yy]=luminance_channel[nearest_nonNaN_X][nearest_nonNaN_Y]
			Multithread full_reconstruction[xx][yy][]=full_reconstruction[nearest_nonNaN_X][nearest_nonNaN_Y][r]	
		endif		
	endfor
endfor
killwaves current_activationwave, reconstruction_lookup

// RGB and GBU reconstructions of 1st 3 Opsin and last 3 maps
make /o/n=(nPx,nPx,3) RGB_reconstruction = NaN
make /o/n=(nPx,nPx,3) GBU_reconstruction = NaN
imagestats/Q reconstructionR
RGB_reconstruction[][][0]=round(((reconstructionR[p][q]-V_min)/(V_Max-V_Min))*2^16)
imagestats/Q reconstructionG
RGB_reconstruction[][][1]=round(((reconstructionG[p][q]-V_min)/(V_Max-V_Min))*2^16)
GBU_reconstruction[][][0]=round(((reconstructionG[p][q]-V_min)/(V_Max-V_Min))*2^16)
imagestats/Q reconstructionB
RGB_reconstruction[][][2]=round(((reconstructionB[p][q]-V_min)/(V_Max-V_Min))*2^16)
GBU_reconstruction[][][1]=round(((reconstructionB[p][q]-V_min)/(V_Max-V_Min))*2^16)
imagestats/Q reconstructionU
GBU_reconstruction[][][2]=round(((reconstructionU[p][q]-V_min)/(V_Max-V_Min))*2^16)

setscale x,-ScanRadius,ScanRadius,"deg" RGB_reconstruction, GBU_reconstruction
setscale y,-ScanRadius,ScanRadius,"deg" RGB_reconstruction, GBU_reconstruction


// z-normalising opsin activation arrays
duplicate /o Opsin_activation Opsin_activation_znorm
variable oo
for (oo=0;oo<nOpsins;oo+=1)
	if (PCA_uses_log_Activation==1)
		make /o/n=(nScanPoints_used) currentwave = log(Opsin_activation[p][oo])
		Wavestats/Q currentwave
		Opsin_activation_znorm[][oo]=log(Opsin_activation[p][oo]) - V_avg
		Opsin_activation_znorm[][oo]/=V_SDev
	else
		make /o/n=(nScanPoints_used) currentwave = Opsin_activation[p][oo]
		Wavestats/Q currentwave
		Opsin_activation_znorm[][oo]=Opsin_activation[p][oo] - V_avg
		Opsin_activation_znorm[][oo]/=V_SDev
	endif
	
endfor

// Principal component analysis (PCA)
make /o/n=(1) M_R
make /o/n=(1) M_C
make /o/n=(1) W_CumulativeVar
PCA /CVAR /SCMT /SRMT Opsin_activation_znorm
duplicate /o M_R Eigenvalues	// Principal components in Eigenvalues[][0]...
duplicate /o M_C Eigenvectors	// Variance of principal components in Eigenvectors[0][]...
Duplicate /o W_CumulativeVar Variance_explained
Variance_explained[1,Dimsize(Variance_explained,0)-1]=W_CumulativeVar[p]-W_CumulativeVar[p-1]
Variance_explained[0]=W_CumulativeVar[0]
Eigenvalues[][]=(Eigenvalues[p][q]==0)?(NaN):(Eigenvalues[p][q])
Eigenvalues[0,2][]=NaN

duplicate /o eigenvalues eigenvalues_rangenorm

for (oo=0;oo<nOpsins;oo+=1)
	make /o/n=(nScanPoints_used) currentwave = eigenvalues[p][oo]
	Wavestats/Q currentwave
	variable MaxRange = V_Max
	if (-V_Min>V_Max)
		maxRange = -V_Min
	endif
	
	eigenvalues_rangenorm[][oo]/=MaxRange

endfor

killwaves M_R, M_C

// Sets up Opsin map reconstructions
make /o/n=(nPx,nPx) reconstructionPC1 = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionPC1
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionPC1

make /o/n=(nPx,nPx) reconstructionPC2 = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionPC2
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionPC2

make /o/n=(nPx,nPx) reconstructionPC3 = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionPC3
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionPC3

make /o/n=(nPx,nPx) reconstructionPC4 = NaN
setscale x,-ScanRadius,ScanRadius,"deg" reconstructionPC4
setscale y,-ScanRadius,ScanRadius,"deg" reconstructionPC4

for (ww=0;ww<nScanPoints_used;ww+=1)
	
	TargetX = ((ScanX_cropped[ww]-90)/ScanRadius) * nPx/2*edge_compression + nPx/2
	TargetY = ((ScanY_cropped[ww]-90)/ScanRadius) * -nPx/2*edge_compression + nPx/2 
	
	reconstructionPC1[TargetX][TargetY]=eigenvalues_rangenorm[ww][0]
	reconstructionPC2[TargetX][TargetY]=eigenvalues_rangenorm[ww][1]
	reconstructionPC3[TargetX][TargetY]=eigenvalues_rangenorm[ww][2]
	reconstructionPC4[TargetX][TargetY]=eigenvalues_rangenorm[ww][3]

endfor

// Interpolates the reconstructed images
duplicate /o reconstructionPC1 reconstruction_lookup

for (xx=interpolate_range;xx<nPx-interpolate_range;xx+=1)
	for (yy=interpolate_range;yy<nPx-interpolate_range;yy+=1)
		distance_from_center = ((nPx/2-xx)^2+(nPx/2-yy)^2)^0.5
		if (distance_from_center<scanrange_px && xx>=XEdgeCrop_px+extracrop_px && xx<=nPx-XEdgeCrop_px-extracrop_px)
			currentmix = 0
			shortestdistance = interpolate_range*2
			for (ipX=-interpolate_range;ipX<interpolate_range+1;ipX+=1)
				for (ipY=-interpolate_range;ipY<interpolate_range+1;ipY+=1)
					if (Numtype(reconstruction_lookup[xx+ipX][yy+ipY])==2)
					else
						currentdistance = (ipX^2+ipY^2)^0.5
						if (currentdistance<shortestdistance)
							shortestdistance = currentdistance
							nearest_nonNaN_X = xx+ipX
							nearest_nonNaN_Y = yy+ipY		
						endif
					endif
				endfor
			endfor
			reconstructionPC1[xx][yy]=reconstructionPC1[nearest_nonNaN_X][nearest_nonNaN_Y]
			reconstructionPC2[xx][yy]=reconstructionPC2[nearest_nonNaN_X][nearest_nonNaN_Y]
			reconstructionPC3[xx][yy]=reconstructionPC3[nearest_nonNaN_X][nearest_nonNaN_Y]
			reconstructionPC4[xx][yy]=reconstructionPC4[nearest_nonNaN_X][nearest_nonNaN_Y]	
		endif		
	endfor
endfor
killwaves reconstruction_lookup

// RGB reconstructions of PC2-4
make /o/n=(nPx,nPx,3) ChromaticPCs_reconstruction=Nan

ChromaticPCs_reconstruction[][][0]=round((reconstructionPC2[p][q]+1)*2^15)
ChromaticPCs_reconstruction[][][1]=round((reconstructionPC3[p][q]+1)*2^15)
ChromaticPCs_reconstruction[][][2]=round((reconstructionPC4[p][q]+1)*2^15)

setscale x,-ScanRadius,ScanRadius,"deg" ChromaticPCs_reconstruction
setscale y,-ScanRadius,ScanRadius,"deg" ChromaticPCs_reconstruction

/// PCA ends

// Displays
make /o/n=4 plotcolourwave = x
 
if (display_stuff==1)
	display /k=1
	ModifyGraph height={Aspect,1}
	ModifyGraph margin=10
	
	ShowTools/A arrow
	SetDrawEnv textrgb= (65535/2,65535/2,65535/2);DelayUpdate
	DrawText 0.0013,0.05,"'"+ 'DataFolder' + "'"
	SetDrawEnv textrgb= (65535/2,65535/2,65535/2);DelayUpdate
	DrawText 0.0013,0.09,'Species'
	
	HideTools/A
 
 	Appendimage /l=Yaxis2 /b=Xaxis1 reconstructionR
	Appendimage /l=Yaxis2 /b=Xaxis2 reconstructionG
	Appendimage /l=Yaxis2 /b=Xaxis3 reconstructionB
	Appendimage /l=Yaxis2 /b=Xaxis4 reconstructionU		
	Appendimage /l=Yaxis1 /b=Xaxis2 RGB_reconstruction
	Appendimage /l=Yaxis1 /b=Xaxis3 GBU_reconstruction	
	
	Appendimage /l=Yaxis3 /b=Xaxis1 reconstructionPC1
	Appendimage /l=Yaxis3 /b=Xaxis2 reconstructionPC2
	Appendimage /l=Yaxis3 /b=Xaxis3 reconstructionPC3
	Appendimage /l=Yaxis3 /b=Xaxis4 reconstructionPC4		
	Appendimage /l=Yaxis1 /b=Xaxis4 ChromaticPCs_reconstruction
	
	Appendtograph /l=YAxis4 /b=XAxisB1 Eigenvectors[0][]
	Appendtograph /l=YAxis4 /b=XAxisB2 Eigenvectors[1][]
	Appendtograph /l=YAxis4 /b=XAxisB3 Eigenvectors[2][]
	Appendtograph /l=YAxis4 /b=XAxisB4 Eigenvectors[3][]		
	
	ModifyGraph fSize=8, lblPos=47, freePos={0,kwFraction}, noLabel=2,axThick=0
	
	ModifyGraph axisEnab(Yaxis2)={0.51,0.75}, axisEnab(Yaxis1)={0.76,1.0},  axisEnab(Yaxis3)={0.26,0.5},  axisEnab(Yaxis4)={0.01,0.25}
	ModifyGraph axisEnab(Xaxis1)={0.01,0.25}, axisEnab(Xaxis2)={0.26,0.5}, axisEnab(Xaxis3)={0.51,0.75}, axisEnab(Xaxis4)={0.76,1.0}
	ModifyGraph axisEnab(XaxisB1)={0.08,0.17}, axisEnab(XaxisB2)={0.33,0.42}, axisEnab(XaxisB3)={0.58,0.67}, axisEnab(XaxisB4)={0.83,0.92}
	
	Label Yaxis1 "\\Z10 \\U"
	Label Yaxis2 "\\Z10 \\U"
	Label Yaxis3 "\\Z10 \\U"
	Label Xaxis1 "\\Z10 \\U"
	Label Xaxis2 "\\Z10 \\U"
	Label Xaxis3 "\\Z10 \\U"
	Label Xaxis4 "\\Z10 \\U"

	ModifyImage reconstructionR ctab= {*,*,Red,0}
	ModifyImage reconstructionG ctab= {*,*,Green,0}
	ModifyImage reconstructionB ctab= {*,*,Blue,0}
	ModifyImage reconstructionU ctab= {*,*,Magenta,0}
	
	ModifyImage reconstructionPC2 ctab= {*,*,Rainbow,1}
	ModifyImage reconstructionPC3 ctab= {*,*,Rainbow,1}
	ModifyImage reconstructionPC4 ctab= {*,*,Rainbow,1}
		
		
	ModifyGraph grid(YAxis4)=1,zero(YAxis4)=1,noLabel(YAxis4)=0,axThick(YAxis4)=1;DelayUpdate
	ModifyGraph gridRGB(YAxis4)=(47872,47872,47872);DelayUpdate
	SetAxis YAxis4 -1,1
	ModifyGraph mode=8,marker=16,msize=3		
	ModifyGraph zColor(Eigenvectors)={plotcolourwave,*,*,Rainbow,0}
	ModifyGraph zColor(Eigenvectors#1)={plotcolourwave,*,*,Rainbow,0}
	ModifyGraph zColor(Eigenvectors#2)={plotcolourwave,*,*,Rainbow,0}
	ModifyGraph zColor(Eigenvectors#3)={plotcolourwave,*,*,Rainbow,0}

SetAxis/A/R Xaxis1;DelayUpdate
SetAxis/A/R Xaxis2;DelayUpdate
SetAxis/A/R Xaxis3;DelayUpdate
SetAxis/A/R Xaxis4

ModifyImage reconstructionPC1 ctab= {-1,1,Grays,0}
ModifyImage reconstructionPC2 ctab= {-1,1,Grays,0}
ModifyImage reconstructionPC3 ctab= {-1,1,Grays,0}
ModifyImage reconstructionPC4 ctab= {-1,1,Grays,0}

if (Chromattype<4)
	ChromaticPCs_reconstruction[][][2]=(Numtype(ChromaticPCs_reconstruction[p][q][0])==0)?(2^15):(NaN)
endif
if (Chromattype<3)
	ChromaticPCs_reconstruction[][][1]=(Numtype(ChromaticPCs_reconstruction[p][q][0])==0)?(2^15):(NaN)
endif

// For fixing single pixels in the display
RGB_reconstruction[][][]=(RGB_reconstruction[p][q][r]>2^16-1)?(2^16-1):(RGB_reconstruction[p][q][r])
RGB_reconstruction[][][]=(RGB_reconstruction[p][q][r]<0)?(0):(RGB_reconstruction[p][q][r])

ChromaticPCs_reconstruction[][][]=(ChromaticPCs_reconstruction[p][q][r]>2^16-1)?(2^16-1):(ChromaticPCs_reconstruction[p][q][r])
ChromaticPCs_reconstruction[][][]=(ChromaticPCs_reconstruction[p][q][r]<0)?(0):(ChromaticPCs_reconstruction[p][q][r])

endif

killwaves currentwave


end


///////////////////////////////////////////////////////////////////////////
///																		   	
/// Z-normalise full_reconstruction hyperspectral videos
/// (i.e. where each wavelength instance is 1 frame).			
/// Requires full_reconstruction wave generated in the analysis function   
///																	
///////////////////////////////////////////////////////////////////////////

function Znormalise(DataFolder)
string DataFolder

wave full_reconstruction

variable nRows = DimSize (full_reconstruction, 0)
variable nColumns = DimSize (full_reconstruction, 1)
variable nLayers = DimSize (full_reconstruction, 2)

make /o/n = (nRows, nColumns, nLayers) full_reconstruction_Znormed = Nan

variable xx
for (xx=0; xx<nLayers; xx+=1)
	make /o/n = (nRows, nColumns) temporal = full_reconstruction[p][q][xx]
	Imagestats /Q temporal
	full_reconstruction_Znormed[][][xx] = temporal[p][q]-V_Avg
	full_reconstruction_Znormed[][][xx]/=V_SDev

endfor


end



//////////////////////////////////////////////////
///
/// Function to generate spiral scanning paths
///
//////////////////////////////////////////////////

function Scanpath_spiral(print_numbers)
variable print_numbers

// Numbers in degrees
variable XYrange = 30
variable Zeropos = 90
variable target_stepsize = 0

variable nPoints = 100

make /o/n=(nPoints) ScanX  = NaN
make /o/n=(nPoints) ScanY = NaN
make /o/n=(nPoints) Angle_Tracker = NaN

variable golden_angle = (137.508/360) * 2 * pi

variable pp,currentangle,currentradius
for (pp=0;pp<nPoints;pp+=1)
	// Fermat's spiral using golden angle of 137.508 degrees which is approximated by Fibonnaci series
	currentradius = sqrt(pp)/sqrt(nPoints)// 0:1 
	currentangle = pp*golden_angle // 0:2*pi
	ScanX[pp]=Zeropos+XYrange*(cos(currentangle)*(currentradius))
	ScanY[pp]=Zeropos+XYrange*(sin(currentangle)*(currentradius))
	// Get angles into 2*pi range
	do
		currentangle-=2*pi
	while (currentangle>2*pi)
	if (currentangle<0)
		currentangle+=2*pi
	endif
	Angle_tracker[pp] = currentangle
endfor

// Travelling Salesman optimisation (brute force approach)
sort Angle_tracker ScanX 
sort Angle_tracker ScanY

make /o/n=(nPoints) Distance_tracker = XYrange*2
duplicate /o ScanX ScanX_new
duplicate /o ScanY ScanY_new

variable whilemax = 2000000
make /o/n=(whilemax) Distance_mean_tracker = NaN
make /o/n=(whilemax) Distance_SD_tracker = NaN
variable whilecounter = 0
variable updatecounter = 0
variable Previous_SD,Previous_mean,New_Mean,New_SD,Swap1,Swap2
do
	whilecounter+=1
	for (pp=0;pp<nPoints;pp+=1)
		Distance_tracker[pp]=((ScanX_new[pp]-ScanX_new[pp+1])^2+(ScanY_new[pp]-ScanY_new[pp+1])^2)^0.5
	endfor
	Distance_tracker[nPoints-1]=NaN
	Wavestats/Q Distance_tracker
	Previous_mean = V_Avg
	Previous_SD = V_SDev
	variable previous_V_Max = V_Max
	
	if (whilecounter>whilemax)
		print "Scan-step distances:", V_Avg, "+/-", V_SDev
		print "Point spacing:", V_Min
		
		break
		
	endif

	Swap1 = Floor(enoise(nPoints/2)+nPoints/2)
	Swap2 = Floor(enoise(nPoints/2)+nPoints/2)
	
	ScanX_new[Swap1]=ScanX[Swap2]
	ScanX_new[Swap2]=ScanX[Swap1]	
	ScanY_new[Swap1]=ScanY[Swap2]
	ScanY_new[Swap2]=ScanY[Swap1]		
		
	for (pp=0;pp<nPoints;pp+=1)
		Distance_tracker[pp]=((ScanX_new[pp]-ScanX_new[pp+1])^2+(ScanY_new[pp]-ScanY_new[pp+1])^2)^0.5
	endfor
	Distance_tracker[nPoints-1]=NaN
	Wavestats/Q Distance_tracker
	New_mean = V_Avg
	New_SD = V_SDev

	if ((New_mean-target_stepsize)^2<(previous_mean-target_stepsize)^2 || V_Max < previous_V_Max)
		ScanX = ScanX_new
		ScanY = ScanY_new
		Distance_mean_tracker[updatecounter]=New_mean
		Distance_SD_tracker[updatecounter]=V_SDev
		updatecounter+=1	
		
	else
		ScanX_new = ScanX
		ScanY_new = ScanY
	endif
		
while(1)

killwaves ScanX_new, ScanY_new, Angle_tracker

string Xpath_str = ""
string Ypath_str = ""
string Xpath_dec_str = ""
string Ypath_dec_str = ""

for (pp=0;pp<nPoints;pp+=1)
	Xpath_str = Xpath_str+Num2Str(floor(ScanX[pp]))+","
	Ypath_str = Ypath_str+Num2Str(floor(ScanY[pp]))+","
	Xpath_dec_str = Xpath_dec_str+Num2Str(10*(round(ScanX[pp]*10)/10-floor(ScanX[pp])))+","
	Ypath_dec_str = Ypath_dec_str+Num2Str(10*(round(ScanY[pp]*10)/10-floor(ScanY[pp])))+","

endfor

if (print_numbers==1)
	print "const int8_t arrayX[] PROGMEM = {    // "
	print Xpath_str
	print "};"
	
	print "const int8_t arrayXdec[] PROGMEM = {    // "
	print Xpath_dec_str
	print "};"	
	
	print "const int8_t arrayY[] PROGMEM = {    // "
	print Ypath_str
	print "};"
		
	print "const int8_t arrayYdec[] PROGMEM = {    // "
	print Ypath_dec_str
	print "};"
	
endif


end


///////////////////////////////////////////////////
///
/// Function to generate rectangle scanning path
///
////////////////////////////////////////////////////

function Scanpath_rectangle(print_numbers)
variable print_numbers

// Numbers in degrees
variable Xrange = 30
variable Yrange = 60
variable Resolution = 3

variable XSteps = XRange/resolution*2
variable YSteps = YRange/resolution*2

variable Zeropos = 90 // In degrees

variable nPoints = XSteps*YSteps

make /o/n=(nPoints) ScanX  = NaN
make /o/n=(nPoints) ScanY = NaN

variable nPoints_calculated = 0
variable xx,yy
for (xx=0;xx<XSteps;xx+=1)
	for (yy=0;yy<YSteps;yy+=1)
		ScanX[nPoints_calculated]=(xx/XSteps-0.5)*Xrange*2+Zeropos	
		if (round(xx/2)==xx/2)
			ScanY[nPoints_calculated]=(yy/YSteps-0.5)*Yrange*2+Zeropos
		else
			ScanY[nPoints_calculated]=((YSteps-1-yy)/YSteps-0.5)*Yrange*2+Zeropos
		endif
		nPoints_calculated+=1
	endfor
endfor

print nPoints, "Steps"

string Xpath_str = ""
string Ypath_str = ""
string Xpath_dec_str = ""
string Ypath_dec_str = ""

variable pp
for (pp=0;pp<nPoints;pp+=1)

	Xpath_str = Xpath_str+Num2Str(floor(ScanX[pp]))+","
	Ypath_str = Ypath_str+Num2Str(floor(ScanY[pp]))+","
	
	Xpath_dec_str = Xpath_dec_str+Num2Str(10*(round(ScanX[pp]*10)/10-floor(ScanX[pp])))+","
	Ypath_dec_str = Ypath_dec_str+Num2Str(10*(round(ScanY[pp]*10)/10-floor(ScanY[pp])))+","
endfor

if (print_numbers==1)
	print "const int8_t arrayX[] PROGMEM = {    // "
	print Xpath_str
	print "};"
	
	print "const int8_t arrayXdec[] PROGMEM = {    // "
	print Xpath_dec_str
	print "};"	
	
	print "const int8_t arrayY[] PROGMEM = {    // "
	print Ypath_str
	print "};"
		
	print "const int8_t arrayYdec[] PROGMEM = {    // "
	print Ypath_dec_str
	print "};"
	
endif


end