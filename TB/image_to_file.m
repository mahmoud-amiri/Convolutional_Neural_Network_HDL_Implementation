% Read the image
imageFile = 'flower.jpg'; % specify your image file
img = imread(imageFile);

% Get the size of the image
[rows, cols, channels] = size(img);

% Open the file to write
outputFile = 'image_with_header.txt'; % specify your output file
fileID = fopen(outputFile, 'w');

% Write the header (size of the image)
fprintf(fileID, '%d ', rows);
fprintf(fileID, '%d ', cols);
fprintf(fileID, '%d ', channels);

% Write the image data
for i = 1:rows
    for j = 1:cols
        for k = 1:channels
            fprintf(fileID, '%d ', img(i, j, k));
        end
    end
    fprintf(fileID, '\n');
end

% Close the file
fclose(fileID);

disp('Image and header written to text file successfully.');
