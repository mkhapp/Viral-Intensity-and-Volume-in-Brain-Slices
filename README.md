# Viral Intensity and Volume in Brain Slices
For Lee Peyton

This macro was written in January 2025 to help Lee Peyton analyze his brain slice images
of viral spread.  He would like to quantify both the total volume of infected brain tissue
and the intensity of fluorescence (as an estimate of viral load) for two separate viruses.
This macro segments the infected brain tissue (via sliding paraboloid background subtraction
and Otsu thresholding) for each separate channel and measures the volume and total intensity
of each.  In order to ensure proper comparison of samples, this macro can only be used for
two channel (red and green) images that are calibrated in microns (not pixels or inches).
The macro generates a results table with the name and measurements for the active image.
If the results table remains open, further results will be appended to the bottom of the table.
The table can be saved as a .csv (which can be opened in Excel) by choosing File/Save As...
in the menus at the top of the Results Table.
