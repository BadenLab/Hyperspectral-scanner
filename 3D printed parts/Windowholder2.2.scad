////Base to hold the lens////

h1=14+2;
r1=(67.3+23.5)/2;

h2=12+2;
r2=(53.3+23.5)/2;

h3=12+2;
r3=(51.3+23.5)/2;

h4=2+2;
r4=(47.8+18.5)/2;

h5=12+2;
r5=(51.3+23.5)/2;


module base_plus(){
    translate ([0,0,0]) {cylinder (h1, r1, r1, $fn = 100, center = true);}
    
    translate ([0,0,13]) {cylinder (h2, r2, r2, $fn = 100, center = true);}
       
}

module base_minus(){
    translate ([0,0,1]) {cylinder (h3, r3, r3, $fn = 100, center = true);}
    
    translate ([0,0,-6]) {cylinder (h4, r4, r4, $fn = 100, center = true);}
    
    translate ([0,0,13]) {cylinder (h5, r5, r5, $fn = 100, center = true);}
    
}

difference() {base_plus(); base_minus();}


////Cap to hold the lens////

h6=15+2;
r6=(51.3+23.5)/2;

h7=2+2;
r7=(55.3+23.5)/2;

h8=10+2;
r8=(67.9+23.5)/2;

h9=15+2;
r9=(47.8+23.5)/2;

h10=8+2;
r10=(55.9+23.5)/2;


module cap1_plus(){
    translate ([150,0,-6.5]) {cylinder (h7, r7, r7, $fn = 100, center = true);}
    
    translate ([150,0,-2.5]) {cylinder (h8, r8, r8, $fn = 100, center = true);}
    
}

module cap1_minus(){
    translate ([150,0,0]) {cylinder (h9, r9, r9, $fn = 100, center = true);}
    
    translate ([150,0,0]) {cylinder (h10, r10, r10, $fn = 100, center = true);}
    
}

module mod1() {difference() {cap1_plus(); cap1_minus();}}

module cap2_plus(){
    translate ([150,0,0]) {cylinder (h6, r6, r6, $fn = 100, center = true);}
    
}

module cap2_minus(){
    translate ([150,0,0]) {cylinder (h9, r9, r9, $fn = 100, center = true);}
  
}


module mod2() {difference() {cap2_plus(); cap2_minus();}}

union() {mod1();mod2();}