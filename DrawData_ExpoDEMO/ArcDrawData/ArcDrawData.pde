// hit "esc" key to quit draw at any time

//TODO change buffer to random number OR some smallish movement from the last x,y coordinate
// NOTE the current csv log read is not configured for 2 myo devices
ArcDraw arcDraw = new ArcDraw();
MoveColorArcDraw moveColorArcDraw = new MoveColorArcDraw();
RelativeTriangleDraw trianglesDraw = new RelativeTriangleDraw();

void setup() {
 size(512, 512); // arcs
// size(1024, 1024); //triangles
  background(0);
}
//*********************
// INIT VARIABLES 
//********************

boolean readFromExcel = true; // if read line-by-line from .txt, set = false
String inputFileName = "../../SensorRead/myo-sdk-win-0.9.0/samples/x64/Debug/outFile.txt"; // either excel or txt
String logFileName = "../../SensorRead/myo-sdk-win-0.9.0/samples/x64/Debug/logFile.csv"; // read not handled yet in this file

// file obj to read from
BufferedReader reader;

//input strings
String inputStr; // reads .txt file input
String[][] acclines; // reads .csv file input (not functional yet) [myo1 vs myo2][x vs y vs z]
String[][] orelines;

// cur accel / orientation reading (to be updated in each loops)
String[][] accdims = new String[2][]; // x/y/z accel values for myo1 (idx 0) & myo2 (idx 1)
String[][] oredims = new String[2][];

//start the acceleration and the orientation vectors at the same point. 
int[][] curraccPoint = {{width/2, height/2}, {width/2, height/2}}; // make 2-d in case we want to separate start points for myo 1 & myo 2 later
int[][] currorePoint = {{width/2, height/2}, {width/2, height/2}};

//initialize directions as 1. When it hits a wall this value will switch. 
int accdirX[] = {1, 1}; // idx = 0: Myo 1, idx = 1: Myo 2.
int accdirY[] = {1, 1};
int oredirX[] = {1, 1};
int oredirY[] = {1, 1};
int i = 1;  //increment for moving around. 

int beatDelay = 10; // TODO change the delay time so that it matches the beat of the music

//start and stop for arc lengths
float[][] ends = {{0, 10}, {0, 10}};
//center for moving arc drawing
float[][] center = {{width/2, height/2}, {width/2, height/2}}; // leave open-ended for possibly having 2 different arc centers (one for each myo)

//****************************
// SUPPORT FUNCTIONS
//****************************
// as safety measure, always mod by width & height to prevent overflow
int[] safeMod(int xVal, int yVal) {
  int[] ret = new int[2]; 
  ret[0] = xVal%width;
  ret[1] = yVal%height;

  return ret; // ret[0] = x, ret[1] = y
}

//****************************
// DRAW() EXECUTING LOOP
//****************************
void draw() {

  //delay(beatDelay);

  //roll1,pitch1,yaw1|accelx1,accely1,accelz1|gyrox1,gyroy1,gyroz1|emgOver1;
  String[][] dataCategory = new String[2][4]; // save separate data strings into this arr ([0] = accellims, [1] = orelims, [2] = gyroz, [3] = emg)

  if (!readFromExcel) {
    // line-by-line .txt data input: opened-close file each time
    reader = createReader(inputFileName); // open file to read

    // read line from that file
    try { 
      inputStr = reader.readLine();
    } 
    catch (Exception e ) {
      System.out.println("HELP exception thrown trying to read .txt input file");
    }    

    if (inputStr != null) {
      String[] myoInstanceData = split(inputStr, ";"); // myoInstanceData[0] is myo 1, myoInstanceData[1] is myo 2
      dataCategory[0] = split(myoInstanceData[0], "|");
      dataCategory[1] = split(myoInstanceData[1], "|");
    } else { // fill dataCategory with dummy string to prevent null pointer exception
      dataCategory[0][0] = "1,1,1"; // acceleration data dummy
      dataCategory[0][1] = "1,1,1"; // orienation data dummy
      dataCategory[0][2] = "1,1,1"; //gyro data dummy
      dataCategory[0][3] = "1"; // emg data dummy

      dataCategory[1][0] = "1,1,1"; // acceleration data dummy
      dataCategory[1][1] = "1,1,1"; // orienation data dummy
      dataCategory[1][2] = "1,1,1"; //gyro data dummy
      dataCategory[1][3] = "1"; // emg data dummy
    }
  } else if (readFromExcel) { //alternate data input: read strings from 2 .csv input files. This will be reading line-by-line from txt in the future. 
    String[] inputCSVLines = loadStrings(logFileName);
    String[] allData = new String[20];

    // if has reached the end of the csv file read
    try {
      allData = split(inputCSVLines[i], ","); // iterates through csv file
      
    if (allData == null) {
      exit();
    }

      if (inputCSVLines == null || inputCSVLines[i] == null) {
        //exit(); 
        stop();
      }
    } 
    catch (Exception EOF) {
      System.out.println("reached end of csv file");
      stop();
      //exit();
    }
      try {
      // myo 1
      dataCategory[0][0] = allData[0]+","+allData[1]+","+allData[2]; // orienation data
      dataCategory[0][1] = allData[3]+","+allData[4]+","+allData[5]; //  acceleration data 
      dataCategory[0][2] = allData[6]+","+allData[7]+","+allData[8]; //gyro data 
      dataCategory[0][3] = allData[9]; // emg data 

      // myo 2
      dataCategory[1][0] = allData[10]+","+allData[11]+","+allData[12]; // orienation data
      dataCategory[1][1] = allData[13]+","+allData[14]+","+allData[15]; //  acceleration data 
      dataCategory[1][2] = allData[16]+","+allData[17]+","+allData[18]; //gyro data 
      dataCategory[1][3] = allData[19]; // emg data
    
    } catch (Exception emptyDataException) {
      System.out.println("allData is null or empty");
    }
  } else {
    System.out.println("ERROR invalid boolean input for readFromExcel");
  }
  
  try {
  // myo 1
  accdims[0] = split(dataCategory[0][1], ","); // x/y/z accel
  oredims[0] = split(dataCategory[0][0], ",");

  // myo 2
  accdims[1] = split(dataCategory[1][1], ","); // x/y/z accel
  oredims[1] = split(dataCategory[1][0], ",");
  } catch (Exception splitDataCategoryException) {
   println("exit file at  splitDataCategoryException");
   exit();
  }


  println("myo 1 accel: "+dataCategory[0][1]+", myo 2 accel: "+dataCategory[1][1]);
  println("myo 1 oredims: "+dataCategory[0][0]+", myo 2 oredims: "+dataCategory[1][0]);
  println();

  //int[] newpoint = pointPlot(orelines[i],curraccPoint));
  //String[] oredims = split(orelines[i], ",");

  int[] pointX = {int(currorePoint[0][0] + int(oredims[0][1])*-oredirX[0] + int(accdims[0][1])*-accdirX[0]), int(currorePoint[0][0] + int(oredims[1][1])*-oredirX[1] + int(accdims[1][1])*-accdirX[1])};  //create new point based off of old
  int[] pointY = {int(currorePoint[0][1] + int(oredims[0][2])*-oredirY[0] + int(accdims[0][2])*-accdirY[0]), int(currorePoint[1][1] + int(oredims[1][2])*-oredirY[1] + int(accdims[1][2])*-accdirY[1])};
  if ((pointX[0] == currorePoint[0][0])&&(pointY[0]==currorePoint[0][1])) { // myo 1 spot check
    //if they're the same does it matter?
  }

  // myo 1
  currorePoint[0][0] = pointX[0]; //update the current orientation, copy the arr
  currorePoint[0][1] = pointY[0]; 

  // myo 2
  currorePoint[1][0] = pointX[1]; 
  currorePoint[1][1] = pointY[1]; 
  // println(str(currorePoint[0]) + ", " + str(currorePoint[1]));  // println for debugging:

  //point(adaptedXpt, adaptedYpt); // make sure the point never overwrites the buffer with %width & %height (it essentially wraps around)

 // linesSlantUp(1, width/8, 3, adaptedXpt, adaptedYpt);

 
   // call from both myo 1 and myo 2 at once (handled by TrianglesDraw class)
   
 //  trianglesDraw.drawTriangles(accdims,oredims, ends[0], center); //triangles
 ends[0] = moveColorArcDraw.drawArc(accdims[1], oredims[0], ends[0], center[0]); // arcs


  if (!readFromExcel) { // if not reading from excel, it's reading from a .txt so we open/close file in each loop
    try {
      reader.close();
    } 
    catch (Exception e ) {
      System.out.println("HELP exception thrown trying to close input file");
    }
  } else {
    i++;  //increment the index one. only valid for excel input (no needed for .txt)
  }
  
  //save("//192.168.2.220/abarai/Servers/aodMARK/www/01.jpg");
  save("C:/Users/emmac/Documents/Bitcamp2018_Art/saveImageFile.jpg");
}

// press "s" at any time to save the current image on screen
void keyPressed() {
  if (key == 's') {
    println("Saving...");
    saveFrame("C:/Users/emmac/Documents/Bitcamp2018s_Art/screen-####.jpg");
    //saveFrame("//192.168.2.220/abarai/Servers/aodMARK/www/screen-####.jpg");
    println("Done saving.");
  }
}
