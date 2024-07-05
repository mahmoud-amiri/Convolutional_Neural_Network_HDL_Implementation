function maxPoolingDemo()
    % Read the 'cameraman.tif' image
    inputImage = imread('cameraman.tif');
    
    % Convert the image to double
    inputImage = double(inputImage);

    % Hyperparameters
    poolSize = 2;
    stride = 2;

    % Perform max pooling
    output = maxPoolingLayer(inputImage, poolSize, stride);

    % Display results
    figure;
    subplot(1, 2, 1);
    imshow(uint8(inputImage));
    title('Input Image');
    
    subplot(1, 2, 2);
    imshow(uint8(output));
    title('Output After Max Pooling');
end



% Run the demo
maxPoolingDemo();
