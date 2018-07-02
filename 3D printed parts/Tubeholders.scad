/// Inside support for the tube ///
/// The inner diameter of the holders has to be adjusted according to the outer diameter of the tube used ///

h5=5;
r5=21;
h6=5;
r7=1.2;
h7=5;
r7=14.6;

module in_plus(){
    translate ([-100,0,0]) {cylinder (h5, r5, r5, $fn = 100, center = true);}

}

module in_minus(){
    translate ([-100,0,0]) {cylinder (h7, r7, r7, $fn = 100, center = true);}

}

{difference(){in_plus(); in_minus();}}


///Outside support for the tube///

h1=70;
h2=8;
r1=80/2;
r2=34/2;
r3=30/2;
r4=48/2;
x=28;
y=80;
z=9;

module plus(){
    translate ([0,0,0]) cylinder (h1, r1, r2, $fn = 100, center = true);
       
}

module minus(){
    translate ([0,0,0]) cylinder (h1, r3, r3, $fn = 100, center = true);
    
    translate ([0,0,-31]) cylinder (h2, r4, r4, $fn = 100, center = true);
    
    translate ([-35,0,-31.5]) cube ([x, y, z], center = true); 
    
}

{difference() {plus(); minus();}}