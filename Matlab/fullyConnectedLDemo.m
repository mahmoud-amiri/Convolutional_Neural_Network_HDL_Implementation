
    % Read the 'cameraman.tif' image
    inputImage = imread('cameraman.tif');
    
    % Convert the image to double
    inputImage = double(inputImage);

    % Flatten the input image to a 1D vector
    inputVector = inputImage(:);

    % Define weights and biases for the fully connected layer
    inputSize = numel(inputVector);
    outputSize = 10;  % Example output size
    weights = rand(outputSize, inputSize);  % Random weights initialization
    biases = rand(outputSize, 1);           % Random biases initialization

    % Perform fully connected layer operation
    output = fullyConnectedLayer(inputVector, weights, biases);

    % Display results
    disp('Input Vector:');
    disp(inputVector);
    disp('Weights:');
    disp(weights);
    disp('Biases:');
    disp(biases);
    disp('Output Vector:');
    disp(output);

