////////////////////////////////////////////////////////
// Hyperspectral scanner by T Baden, www.badenlab.org //
////////////////////////////////////////////////////////

tol = 0.1;

show_base = 1;
show_mirrors1 = 1;
show_mirrors2 = 1;

/////////////////////
/// BASEPLATE (A) ///
/////////////////////

Rim = 3;

A_X = 130;
A_Y = 170;
A_Z = 3;

A_SpectroX = 120+tol;
A_SpectroY = 79.5+tol;
A_SpectroZ = 2;

A_Spectro_footspaceX = 75.5;
A_Spectro_footspaceY = 60.5;
A_Spectro_footXoffset = -15.5-17.5;
A_Spectro_footYoffset = 12;
A_Spectro_footR = 7.5/2;
A_Spectro_footZ = 1;

SpectroRim = 15;

A_SpectroZ_elevation = 17; 

A_entryZoffset = 20;
A_entryXoffset = -13;


A_ServoX = 22.7 + tol;
A_ServoY = 12.3 + tol;
A_ServoZ = 16.2 + tol;
A_ServoZfull = 22.5;
A_ServoXoffset = 5;
A_ServoZ_floatextra = 18;

A_Servo1Distance = 30;
A_Servo2elevation = A_entryZoffset-A_ServoY/2;
A_Servo2Distance = 18;

Battery_Xmainoffset = -35;
Battery_Ymainoffset = -69;
Battery_X = 45+tol;
Battery_Y = 26.3+tol;
Battery_Z = 3;
Battery_Wall = 2;

Pinholemount_X = 15+tol;
Pinholemount_Y = 3+tol;
Pinholemount_Z = 3+tol;
Pinholemount_YOffset = -10;


%translate([A_entryXoffset,-A_Servo1Distance/2,A_Z/2+A_entryZoffset+A_SpectroZ_elevation]){ rotate([90,0,0]){ cylinder(r = 1, h=A_Servo1Distance, center = true);}} // Spectro entry
%translate([A_entryXoffset+A_Servo2Distance/2,-A_Servo1Distance,A_Z/2+A_entryZoffset+A_SpectroZ_elevation]){ rotate([0,90,0]){ cylinder(r = 1, h=A_Servo2Distance, center = true);}} // Beam1
%translate([A_entryXoffset+A_Servo2Distance,-A_Servo1Distance,A_Z/2+A_entryZoffset+A_Servo2elevation/2+A_SpectroZ_elevation]){ rotate([0,0,0]){ cylinder(r = 1, h=A_Servo2elevation, center = true);}} // Beam2

module base_plus() {
    translate([0,-Rim/2,A_Z/2]){ cube(([A_SpectroX,A_Y-Rim,A_Z]), center = true);} // BASE
    
    translate([0,A_Y/2-A_SpectroY/2-Rim,A_Z+A_SpectroZ_elevation/2]){ cube(([A_SpectroX,A_SpectroY,A_SpectroZ_elevation]), center = true);} // Spectro mount
    
    translate([A_entryXoffset-A_ServoXoffset,-A_Servo1Distance,A_Z/2+A_ServoZ/2]){ cube(([A_ServoZfull+Rim*2,A_ServoY+Rim*2,A_ServoZ-A_Z]), center = true);} // Servo1Block
    
    translate([A_Servo2Distance-A_ServoXoffset-mirror_Z/2*cos(45),Rim/2-A_Servo1Distance-A_ServoZ-A_ServoZ_floatextra-(mirror2_X-mirror_X)/2,A_Z/2+A_Servo2elevation/2+A_SpectroZ_elevation/2+Rim+mirror_Z/2*cos(45)]){ cube(([A_ServoX+Rim*2,A_ServoZ+Rim,A_Servo2elevation+A_SpectroZ_elevation+Rim*3]), center = true);} // Servo2Block
    
    translate([A_entryXoffset,Pinholemount_YOffset,A_Z+Pinholemount_Z/2]){ cube(([Pinholemount_X+Rim*2,Pinholemount_Y+Rim*2,Pinholemount_Z]), center = true);} // Pinholemount
    
    translate([Battery_Xmainoffset,Battery_Ymainoffset,A_Z+Battery_Z/2]){ cube(([Battery_X+Battery_Wall*2,Battery_Y+Battery_Wall*2,Battery_Z]), center = true);} // Battery_Block

}

module base_minus() {
    translate([A_Spectro_footXoffset,A_Spectro_footYoffset,A_SpectroZ_elevation+A_Z-A_Spectro_footZ/2]){ cylinder($fn = 50, r=A_Spectro_footR, h= A_Spectro_footZ, center = true);} // Spectro footgroove1
    
    translate([A_Spectro_footXoffset,A_Spectro_footYoffset+A_Spectro_footspaceY,A_SpectroZ_elevation+A_Z-A_Spectro_footZ/2]){ cylinder($fn = 50, r=A_Spectro_footR, h= A_Spectro_footZ, center = true);} // Spectro footgroove2
    
    translate([A_Spectro_footXoffset+A_Spectro_footspaceX,A_Spectro_footYoffset,A_SpectroZ_elevation+A_Z-A_Spectro_footZ/2]){ cylinder($fn = 50, r=A_Spectro_footR, h= A_Spectro_footZ, center = true);} // Spectro footgroove3
    
    translate([A_Spectro_footXoffset+A_Spectro_footspaceX,A_Spectro_footYoffset+A_Spectro_footspaceY,A_SpectroZ_elevation+A_Z-A_Spectro_footZ/2]){ cylinder($fn = 50, r=A_Spectro_footR, h= A_Spectro_footZ, center = true);} // Spectro footgroove4
    
    translate([0,A_Y/2-A_SpectroY/2-Rim,A_Z+A_SpectroZ_elevation/2]){ cube(([A_SpectroX-SpectroRim,A_SpectroY-SpectroRim*2,A_SpectroZ_elevation]), center = true);} // Spectro maingroove
    
    translate([A_entryXoffset-A_ServoXoffset,-A_Servo1Distance,0]){ cube(([A_ServoX,A_ServoY,100]), center = true);} // Servo1 groove  
   
    translate([A_Servo2Distance-A_ServoXoffset-mirror_Z/2*cos(45),-A_Servo1Distance-A_ServoZfull-A_ServoZ_floatextra,A_Z+A_Servo2elevation+A_SpectroZ_elevation+A_ServoY/2-Rim/2+mirror_Z/2*cos(45)]){ cube(([A_ServoX,100,A_ServoY]), center = true);} // Servo2 groove 
    
    translate([A_entryXoffset-A_ServoXoffset+A_ServoX/2,-A_Servo1Distance,0]){cylinder(r = 4, h=100, center = true);} // Servo1 cablegroove
     
    translate([A_Servo2Distance-A_ServoXoffset-10,-A_Servo1Distance-A_ServoZfull-A_ServoZ_floatextra,A_Z+A_Servo2elevation+A_SpectroZ_elevation+A_ServoY/2-Rim/2+mirror_Z/2*cos(45)]){ cube(([30,4,Rim*3]), center = true);} // Servo2 cablegroove
    
    translate([Battery_Xmainoffset,Battery_Ymainoffset,A_Z+Battery_Z/2]){ cube(([Battery_X,Battery_Y,Battery_Z]), center = true);} // Battery_Block
    
    translate([A_entryXoffset,Pinholemount_YOffset,A_Z+Pinholemount_Z/2]){ cube(([Pinholemount_X,Pinholemount_Y,Pinholemount_Z]), center = true);} // Pinholemount
    
}

if (show_base == 1){difference(){base_plus();base_minus();}}


/////////////////////////////
/// Mirror holders (B1, 2)
/////////////////////////////

mirror_X = 12.7+tol;
mirror_Y = 12.7+tol;
mirror_Z = 6+tol;

mirror2_X = 25.4+tol;
mirror2_Y = 25.4+tol;
mirror2_Z = 6+tol;

Holder_rim = 1;
Holder_X_extra = 2;

%translate([A_entryXoffset-mirror_Z/2*cos(45),-A_Servo1Distance-mirror_Z/2*cos(45),mirror_X/2+A_Z/2+A_entryZoffset-mirror_Y/2-Holder_rim+A_SpectroZ_elevation]){ rotate([90,0,-45]){ cube(([mirror_X,mirror_Y,mirror_Z]), center = true);}} // Mirror1

%translate([A_entryXoffset+A_Servo2Distance+mirror_Z/2*cos(45),-A_Servo1Distance,A_Z/2+A_entryZoffset+A_SpectroZ_elevation-mirror_Z/2*cos(45)]){ rotate([0,-45,0]){ cube(([mirror2_X,mirror2_Y,mirror2_Z]), center = true);}} // Mirror2

mirrorbase_Y = mirror_Z+Holder_rim*2;
mirrorbase_X = mirror_X+Holder_rim*2;
mirrorbase_Z = 3;
mirrorbase1_shift = 6;

mirrorbase2_Y = mirror2_Z+Holder_rim*2;
mirrorbase2_X = mirror2_X+Holder_rim*2;
mirrorbase2_Z = 3;

mirror_screw_R = 1.2;
mirror_screw_Offset = 16.7/2;
mirror_screw_Offset_short = 8.7/2;
mirror_screwgroove_R = 2;

module mirror1_plus() {
    translate([0,-mirror_Z/2,mirrorbase_Z/2]){ cube(([mirrorbase_X,mirrorbase_Y,mirrorbase_Z]), center = true);} // Mirror base
    
    translate([0,-mirrorbase1_shift/2,mirrorbase_Z/2]){ cube(([mirrorbase_Y,mirrorbase_X-mirrorbase1_shift+Holder_X_extra,mirrorbase_Z]), center = true);} // Mirror base arm
    
    translate([0,-mirrorbase1_shift+mirrorbase_X/2+Holder_X_extra-Holder_rim,mirrorbase_Z/2]){ cylinder($fn=50, r=mirrorbase_Y/2, h=mirrorbase_Z, center = true);} // Mirror base rounding 1
    
    translate([0,-mirrorbase_X/2-Holder_X_extra+Holder_rim,mirrorbase_Z/2]){ cylinder($fn=50, r=mirrorbase_Y/2, h=mirrorbase_Z, center = true);} // Mirror base rounding 2
           
}

module mirror2_plus() {
    translate([0,-mirror_Z/2,mirrorbase2_Z/2]){ cube(([mirrorbase2_X,mirrorbase2_Y,mirrorbase2_Z]), center = true);} // Mirror base
    
    translate([0,0,mirrorbase2_Z/2]){ cube(([mirrorbase2_Y,mirrorbase2_X/2+Holder_X_extra,mirrorbase2_Z]), center = true);} // Mirror base arm
    
    translate([0,mirrorbase2_X/4+Holder_X_extra-Holder_rim,mirrorbase2_Z/2]){ cylinder($fn=50, r=mirrorbase2_Y/2, h=mirrorbase2_Z, center = true);} // Mirror base rounding 1
    
    translate([0,-mirrorbase2_X/4-Holder_X_extra+Holder_rim,mirrorbase2_Z/2]){ cylinder($fn=50, r=mirrorbase2_Y/2, h=mirrorbase2_Z, center = true);} // Mirror base rounding 2
           
}

module mirror1_minus() {
    translate([0,-mirror_Z/2,mirror_X/2+Holder_rim]){ rotate([90,0,0]){ cube(([mirror_X+0.1,mirror_Y,mirror_Z+0.1]), center = true);}} // Mirror1
    
    translate([0,mirror_screw_Offset_short,mirrorbase_Z/2]){ cylinder($fn=50, r=mirror_screw_R, h=mirrorbase_Z, center = true);} // screwhole 1
    
    translate([0,mirror_screw_Offset_short-1,mirrorbase_Z/2]){ cylinder($fn=50, r=mirror_screw_R, h=mirrorbase_Z, center = true);} // screwhole 1b
    
    translate([0,mirror_screw_Offset_short-2,mirrorbase_Z/2]){ cylinder($fn=50, r=mirror_screw_R, h=mirrorbase_Z, center = true);} // screwhole 1b
    
    translate([0,-mirror_screw_Offset,mirrorbase_Z/2]){ cylinder($fn=50, r=mirror_screw_R, h=mirrorbase_Z, center = true);} // screwhole 2
    
    translate([0,0,mirrorbase_Z/2]){ cylinder($fn=50, r=mirror_screwgroove_R, h=mirrorbase_Z, center = true);} // screwgroove

}

module mirror2_minus() {
    translate([0,-mirror_Z/2,mirror2_X/2+Holder_rim]){ rotate([90,0,0]){ cube(([mirror2_X+0.1,mirror2_Y,mirror2_Z+0.1]), center = true);}} // Mirror1
    
    translate([0,mirror_screw_Offset,mirrorbase2_Z/2]){ cylinder($fn=50, r=mirror_screw_R, h=mirrorbase2_Z, center = true);} // screwhole 1
    
    translate([0,-mirror_screw_Offset,mirrorbase2_Z/2]){ cylinder($fn=50, r=mirror_screw_R, h=mirrorbase2_Z, center = true);} // screwhole 2
    
    translate([0,0,mirrorbase2_Z/2]){ cylinder($fn=50, r=mirror_screwgroove_R, h=mirrorbase_Z, center = true);} // screwgroove

}

if (show_mirrors1==1){translate([A_entryXoffset,-A_Servo1Distance,A_Z/2+A_entryZoffset-mirror_Y/2-Holder_rim+A_SpectroZ_elevation]){rotate([0,0,-45]){difference(){mirror1_plus();mirror1_minus();}}}}

if (show_mirrors2==1){translate([A_entryXoffset+A_Servo2Distance,-A_Servo1Distance-mirror2_Y/2,A_Z/2+A_entryZoffset+A_SpectroZ_elevation]){rotate([-90,135,0]){difference(){mirror2_plus();mirror2_minus();}}}}