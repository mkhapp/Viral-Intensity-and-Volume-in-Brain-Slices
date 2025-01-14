//This macro was written in January 2025 to help Lee Peyton analyze his brain slice images
//of viral spread.  He would like to quantify both the total volume of infected brain tissue
//and the intensity of fluorescence (as an estimate of viral load) for two separate viruses.
//This macro segments the infected brain tissue (via sliding paraboloid background subtraction
//and Otsu thresholding) for each separate channel and measures the volume and total intensity
//of each.  In order to ensure proper comparison of samples, this macro can only be used for
//two channel (red and green) images that are calibrated in microns (not pixels or inches).
//The macro generates a results table with the name and measurements for the active image.
//If the results table remains open, further results will be appended to the bottom of the table.
//The table can be saved as a .csv (which can be opened in Excel) by choosing File/Save As...
//in the menus at the top of the Results Table.


//code starts here

//get and check image properties; create Results Table if necessary
setBatchMode(true);
run("Clear Results");
if (isOpen("ResultsTable") == false) {
	Table.create("ResultsTable");
}
rowIndex = Table.size("ResultsTable");

name = getTitle();
getDimensions(width, height, channels, slices, frames);
	if (channels != 2) {
		exit(name + " is not a 2 channel image.");
	}
getVoxelSize(width, height, depth, unit);
	if (unit != "microns") {
		exit(name + " is not measured in microns.");
	}
	

//split channels to process separately
run("Split Channels");
images = getList("image.titles");

//process channel 1 using functions below
channel1 = channelgetter(images[0]);
vol1 = volumegetter(images[0], depth);
result1 = integrateddensity(images[0]);

//process channel 2 using functions below
channel2 = channelgetter(images[1]);
vol2 = volumegetter(images[1], depth);
result2 = integrateddensity(images[1]);

//save results in data table and close all images
Table.set("Name", rowIndex, name, "ResultsTable");
Table.set(channel1 + " Volume (microns^3)", rowIndex, vol1, "ResultsTable");
Table.set(channel2 + " Volume (microns^3)", rowIndex, vol2, "ResultsTable");
Table.set(channel1 + " Intensity", rowIndex, result1, "ResultsTable");
Table.set(channel2 + " Intensity", rowIndex, result2, "ResultsTable");
close("*");



//processing functions

function channelgetter(title) { 
// determines the channel of the image, and ensures that it is either green or red
selectImage(title);
getLut(reds, greens, blues);
Array.getStatistics(reds, redmin, redmax, redmean, redstdDev);
Array.getStatistics(greens, greenmin, greenmax, greenmean, greenstdDev);
Array.getStatistics(blues, bluemin, bluemax, bluemean, bluestdDev);
channel = "other";
if (redmax > 0 && greenmax == 0 && bluemax == 0) {
	channel = "Red";
}
if (greenmax > 0 && redmax == 0 && bluemax == 0) {
	channel = "Green";
}
if (channel == "other") {
	exit("Channels should be red and green. Please check your image.");
}
return channel;
}

function volumegetter(title, depth) { 
// determines the volume of the measured segment by first segmenting (background subtraction and Otsu thresholding based on middle slice), then adding up the slice areas and multiplying by the slice depth.
run("Set Measurements...", "area limit redirect=None decimal=0");
selectImage(title);

//segment
run("Duplicate...", "duplicate");
rename("AreaImage");
run("Subtract Background...", "rolling=50 sliding stack");
setSlice(round(nSlices/2));
setAutoThreshold("Otsu dark");
run("Convert to Mask", "method=Otsu background=Dark");

//measure
setThreshold(1, 255);
for (i = 1; i <= nSlices; i++) {
	setSlice(i);
	run("Measure");
}

//sum areas
array = Table.getColumn("Area", "Results");
area = 0;
for (i = 0; i < nResults; i++) {
	area = area + Table.get("Area", i, "Results");
}

//volume = areasum * slice depth
volume = round(area*depth);

//clear, close, and return volume
run("Clear Results");
close("Results");
close("AreaImage");
return volume;
}


function integrateddensity(title) { 
// determines the pixel-by-pixel sum of intensities by first segmenting (background subtraction and Otsu thresholding based on middle slice), then adding up the slice areas and multiplying by the slice depth.
run("Set Measurements...", "integrated redirect=None decimal=0");
selectImage(title);
rename("Image");

//segment
run("Duplicate...", "duplicate");
run("Subtract Background...", "rolling=50 sliding stack");
setSlice(round(nSlices/2));
setAutoThreshold("Otsu dark");
run("Convert to Mask", "method=Otsu background=Dark");
run("Divide...", "value=255 stack");
rename("Mask");
imageCalculator("Multiply create stack", "Image","Mask");
close("Mask");

//measure
run("Clear Results");
selectImage("Result of Image");
for (i = 1; i <= nSlices; i++) {
	setSlice(i);
	run("Measure");
}

//add intensities for each slice
array = Table.getColumn("RawIntDen", "Results");
intden = 0;
for (i = 0; i < nResults; i++) {
	intden = intden + Table.get("RawIntDen", i, "Results");
}

//clear, close, and return volume
run("Clear Results");
close("Results");
close("Result of Image");
return intden;
}