% MATLAB script to write the content of an image to a file with size header

% Read the image
imageFile = 'cameraman.tif'; % specify your image file
img = imread(imageFile);

% Get the size of the image
[rows, cols, channels] = size(img);

% Open the file to write
outputFile = 'image_with_header.bin'; % specify your output file
fileID = fopen(outputFile, 'w');

% Write the header (size of the image)
fwrite(fileID, rows, 'uint32');
fwrite(fileID, cols, 'uint32');
fwrite(fileID, channels, 'uint32');

% Write the image data
fwrite(fileID, img, 'uint8');

% Close the file
fclose(fileID);

disp('Image and header written to file successfully.');
