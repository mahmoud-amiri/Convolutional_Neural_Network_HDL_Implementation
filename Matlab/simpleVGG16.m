function output = simpleVGG16Wrapper()
    % Load the cameraman image
    input = imread('cameraman.tif');
    input = imresize(input, 0.5); % Resize for faster processing
    input = im2double(input); % Convert to double
    input = repmat(input, [1, 1, 3]); % Convert to 3-channel image by replicating the grayscale image

    % Load your custom functions
    addpath('path_to_your_functions'); % Replace with the actual path to your function files

    % Define filter sizes and other parameters
    filter1 = randn(3, 3, size(input, 3), 64); % 3x3 filter, depth equal to input depth, 64 filters
    filter2 = randn(3, 3, 64, 64);            % 3x3 filter, depth 64, 64 filters
    stride = 1;
    padding = 1;
    poolSize = 2;
    poolStride = 2;

    % First convolutional layer
    disp('Applying first convolutional layer...');
    conv1 = convolutionLayer(input, filter1, stride, padding);
    relu1 = relu(conv1);
    disp('First convolutional layer completed.');

    % Second convolutional layer
    disp('Applying second convolutional layer...');
    conv2 = convolutionLayer(relu1, filter2, stride, padding);
    relu2 = relu(conv2);
    disp('Second convolutional layer completed.');

    % Max pooling layer
    disp('Applying max pooling layer...');
    pooled = maxPoolingLayer(relu2, poolSize, poolStride);
    disp('Max pooling layer completed.');

    % Flatten the output of the pooling layer
    disp('Flattening the output...');
    flattened = reshape(pooled, [], 1);
    disp('Flattening completed.');

    % Define fully connected layer parameters
    numClasses = 10; % Number of classes for the output
    fcWeights = randn(numClasses, length(flattened)); % Output units equal to number of classes
    fcBiases = randn(numClasses, 1);

    % Fully connected layer
    disp('Applying fully connected layer...');
    fcOutput = fullyConnectedLayer(flattened, fcWeights, fcBiases);
    disp('Fully connected layer completed.');

    % ReLU activation for fully connected layer
    disp('Applying ReLU activation to fully connected layer output...');
    output = relu(fcOutput);
    disp('ReLU activation completed.');

    % Display output size
    disp('Output size:');
    disp(size(output));
end

% Example usage
output = simpleVGG16Wrapper();
