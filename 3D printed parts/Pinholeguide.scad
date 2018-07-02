// Pinholes used for the hyperspectral scanner

y = 15;
r1 = y/2;
x = 37.5+r1;

z = 2.4;

h1 = 20.5-z*2;
r2 = (y/2-1);
r3 = 3/2; // The size of the pinhole, radius in mm

module plus () {
    translate ([x/2-r1,0,0]) {cube (([x, y, z]), center = true);}
    
    translate ([0,0,h1/2+z/2]) {cylinder (h1, r1, r1, $fn = 100, center = true);}

}

module minus (){
    translate ([0,0,h1/2+z/2]) {cylinder (h1, r2, r2, $fn = 100, center = true);}
    
    translate ([0,0,0]) {cylinder (z, r3, r3, $fn = 100, center = true); }
   
}

{difference(){ plus(); minus ();}}




