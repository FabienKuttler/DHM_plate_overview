
//	***********************************************************************************************
//	*******                                                                                 *******
//	*******            Macro for DHM plate SNAPSHOT generation for fiji or imagej           *******
//	*******         Fabien Kuttler, 2022, EPFL-SV-PTECH-PTCB BSF, http://bsf.epfl.ch        *******
//	*******                                                                                 *******
//	***********************************************************************************************

folder = getDirectory("Folder to process (Select the main folder generated by Matlab reconstruction):");
plateNbini = 1;
setMin = 800;
setMax = 5000;
formatPlate = newArray("96-well", "384-well", "Custom (partial plate)");
emptyColor = newArray("Gray", "Black", "White");
fovformat=newArray("1 FOV (1x1)", "4 FOV (2x2)", "9 FOV (3x3)", "16 FOV (4x4)", "25 FOV (5x5)", "36 FOV (6x6)", "Custom");
scaleBar=newArray("no", "yes");
Dialog.create("DHM Snapshot creation");
Dialog.addChoice("Plate format:", formatPlate);
Dialog.addChoice("Number of FOV per well:", fovformat);
Dialog.addNumber("Number of indexes (0:automatic, for full plates only):", plateNbini);
Dialog.addChoice("Add a scale bar?", scaleBar);
Dialog.addChoice("Which color for non-acquired images?", emptyColor);
Dialog.addMessage("Rescaling intensity settings:")
Dialog.addNumber("Minimum (default 800, adipocytes 400)", setMin);
Dialog.addNumber("Maximum (default 5000, adipocytes 15000)", setMax);
Dialog.show();
formatPlate = Dialog.getChoice();
fovformat = Dialog.getChoice();
plateNbini = Dialog.getNumber();
scaleBar = Dialog.getChoice();
emptyColor = Dialog.getChoice();
setMin = Dialog.getNumber();
setMax = Dialog.getNumber();

if(scaleBar == "yes") {
	scaleBarWidth = 500;
	scaleBarHeight = 20;
	fontSize = 100;
	location = newArray("Lower Right", "Lower Left", "Upper Right", "Upper Left");
	Dialog.create("Scale Bar settings");
	Dialog.addNumber("Width in um:", scaleBarWidth);
	Dialog.addNumber("Height in um:", scaleBarHeight);
	Dialog.addNumber("Font size:", fontSize);
	Dialog.addChoice("Scale Bar location:", location);
	Dialog.show();
	scaleBarWidth = Dialog.getNumber();
	scaleBarHeight = Dialog.getNumber();
	fontSize = Dialog.getNumber();
	location = Dialog.getChoice();
}

///////////////////////////////////////////////////////////////
imageFolder = folder + "/all_wells";
File.makeDirectory(folder + "/snapshot");
if(fovformat=="4 FOV (2x2)"){
	fov = 4;
	colsFov = 2;
	rowsFov = 2;
}
if(fovformat=="9 FOV (3x3)"){
	fov = 9;
	colsFov = 3;
	rowsFov = 3;
}
if(fovformat=="16 FOV (4x4)"){
	fov = 16;
	colsFov = 4;
	rowsFov = 4;
}
if(fovformat=="25 FOV (5x5)"){
	fov = 25;
	colsFov = 5;
	rowsFov = 5;
}
if(fovformat=="36 FOV (6x6)"){
	fov = 36;
	colsFov = 6;
	rowsFov = 6;
}
if(fovformat=="1 FOV (1x1)"){
	fov = 1;
	colsFov = 1;
	rowsFov = 1;
}
if(fovformat=="Custom"){
	colsFov = 4;
	rowsFov = 3;
	Dialog.create("Custom FOV format selection");
	Dialog.addNumber("Number of columns of FOV:", colsFov);
	Dialog.addNumber("Number of rows of FOV:", rowsFov);
	Dialog.show();
	colsFov = Dialog.getNumber();
	rowsFov = Dialog.getNumber();
	fov = colsFov*rowsFov;
}
///////////////////////////////////////////////////////////////
start_h = 0;
start_k = 1;
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);

if(formatPlate=="384-well") {
	letters = newArray("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P");
	hmax = 16;
	kmax = 25;
	nbWells = 384;
	cols = 24;
	rows = 16;
}
if(formatPlate=="96-well") {
	letters = newArray("A","B","C","D","E","F","G","H");
	hmax = 8;
	kmax = 13;
	nbWells = 96;
	cols = 12;
	rows = 8;
}
if(formatPlate=="Custom (partial plate)") {
	letters = newArray("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P");
	numbers = newArray("01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24");
	Dialog.create("partial plate overview");
	Dialog.addMessage("FIRST well of the overview: ", 18, "red");
	Dialog.addChoice("               row", letters, "A");
	Dialog.addToSameRow();	
	Dialog.addChoice("   column",numbers, "01");
	Dialog.addMessage("LAST well of the overview: ", 18, "blue");
	Dialog.addChoice("               row", letters, "H");
	Dialog.addToSameRow();	
	Dialog.addChoice("   column",numbers, "12");	
	Dialog.show();	
	firstRowLetter = Dialog.getChoice();
	firstColumnNumber = Dialog.getChoice();
	lastRowLetter = Dialog.getChoice();
	lastColumnNumber = Dialog.getChoice();		
	firstColumn = parseInt(firstColumnNumber);
	lastColumn = parseInt(lastColumnNumber);
	if(firstColumn>lastColumn){exit("Error in selection of first and last columns");}		
	start_h = indexOf("ABCDEFGHIJKLMNOP", firstRowLetter);
	hmax = 1+(indexOf("ABCDEFGHIJKLMNOP", lastRowLetter));
	if(start_h>(hmax-1)){exit("Error in selection of first and last rows");}
	start_k = firstColumn;
	kmax = 1+lastColumn;
	cols = (lastColumn-firstColumn)+1;
	rows = hmax-start_h;
	wells = cols*rows;
}

if(emptyColor=="Gray") {
	emptyColorValue = 15000;
}
if(emptyColor=="Black") {
	emptyColorValue = 0;
}
if(emptyColor=="White") {
	emptyColorValue = 65535;
}

// plate number calculation///////////////////////////////////
if(plateNbini !=0) {
	plateNb = plateNbini;
}
else{
	for (hbis = 0; hbis<hmax; hbis++){
		jbis = letters[hbis];
		for (kbis = 1; kbis<kmax; kbis++) {
			if (kbis<10) {	ibis = "0" + kbis;} 
			else{ibis = kbis;}
			for (mbis = 0; mbis<fov; mbis++) 	{
				if (mbis<10) {fovallbis = "0" + mbis;}
				else{fovallbis = mbis;}
				setBatchMode(true);
				if(File.exists(imageFolder + "/" + jbis + ibis + "/" + "00001_" + fovallbis + "_AK_OPL.tif")){
					filelistinFirstFolder = getFileList(imageFolder + "/" + jbis + ibis);
					plateNb = filelistinFirstFolder.length/fov;
				}
				else {continue;}
			}
		}
	}
}
// loop throught images /////////////////////////////////////////////
for (n = 1; n<plateNb+1; n++){
	for (h = start_h; h<hmax; h++){
		j = letters[h];
		for (k = start_k; k<kmax; k++) {
			if (k<10) {	i = "0" + k;} 
			else 	  {i = k;}
			for (m = 0; m<fov; m++) 	{
				if (m<10) {fovall = "0" + m;}
				else{fovall = m;}
				setBatchMode(true);
				if(n<10){zeros = "0000";}
				else {zeros = "000";}
				if(File.exists(imageFolder + "/" + j + i + "/" + zeros + n + "_" + fovall + "_AK_OPL.tif")){
					open(imageFolder + "/" + j + i + "/" + zeros + n + "_" + fovall + "_AK_OPL.tif");
					run("Size...", "width=300 height=300 depth=1 constrain average interpolation=Bilinear");
					setMinAndMax(setMin, setMax);
				}
				else {
					newImage("AK_empty", "16-bit gray", 300, 300, 1);
					run("Add...", "value=" + emptyColorValue + "");
				}
			}
			if(fovformat=="1 FOV (1x1)"){
				rename(j + i);	
				run("Rotate 90 Degrees Right");
				run("Label...", "format=Text starting=0 interval=1 x=5 y=5 font=50 text=" + j + i + "  range=1-1 use use_text");
				run("Flatten");
				selectWindow(j + i);
				run("Close");
			}
			else{
				run("Images to Stack", "name=Stack title=AK use");
				run("Rotate 90 Degrees Right");
				run("Make Montage...", "columns=" + colsFov + " rows=" + rowsFov + " scale=1");
				selectWindow("Stack");
				run("Close");
				selectWindow("Montage");
				run("Label...", "format=Text starting=0 interval=1 x=5 y=5 font=100 text=" + j + i + "  range=1-1 use use_text");
				run("Flatten");
				selectWindow("Montage");
				run("Close");
				selectWindow("Montage-1");
				rename(j + i);
			}   
		}
	}
	run("Images to Stack", "name=Stack title=[] use");
	run("Make Montage...", "columns=" + cols + " rows=" + rows + " scale=1 border=2");
	selectWindow("Stack");
	run("Close");
	selectWindow("Montage");
		
	if(scaleBar == "yes"){	
		Stack.setXUnit("um");
		Stack.setYUnit("um");
		// pixel size, original from DHM 0.605 * 0.64, adapted here due to resizing from 800*800 to 300*300
		run("Properties...", "channels=1 slices=1 frames=1 pixel_width=1.6133 pixel_height=1.7067 voxel_depth=0.605");
		run("Scale Bar...", "width=" + scaleBarWidth + " height=" + scaleBarHeight + " font=" + fontSize + " color=White background=None location=[" + location + "] bold overlay");
	}
	else{
		Stack.setXUnit("um");
		Stack.setYUnit("um");
		// pixel size, original from DHM 0.605 * 0.64, adapted here due to resizing from 800*800 to 300*300
		run("Properties...", "channels=1 slices=1 frames=1 pixel_width=1.6133 pixel_height=1.7067 voxel_depth=0.605");
	}

	saveAs("jpeg", folder + "/snapshot/index_" + zeros + n + ".jpg");
	while (nImages>0) {
		selectImage(nImages);
		close();
	} 
}
print("\\Clear");
print("Snapshot creation finished");
