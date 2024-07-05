function convLDemo()
    % Read the 'cameraman.tif' image
    inputImage = imread('cameraman.tif');
    
    % Convert the image to double
    inputImage = double(inputImage);

    % Example filter (3x3 Sobel filter for edge detection)
    filter = [
        1 0 -1;
        1 0 -1;
        1 0 -1
    ];

    % Hyperparameters
    stride = 1;
    padding = 1;

    % Perform convolution
    output = convolutionLayer(inputImage, filter, stride, padding);

    % Display results
    figure;
    subplot(1, 3, 1);
    imshow(uint8(inputImage));
    title('Input Image');
    
    subplot(1, 3, 2);
    imshow(filter, []);
    title('Filter');
    
    subplot(1, 3, 3);
    imshow(uint8(output));
    title('Output Feature Map');
end





% Run the demo
convLDemo();
