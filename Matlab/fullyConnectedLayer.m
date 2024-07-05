function output = fullyConnectedLayer(input, weights, biases)
    % Compute the output of the fully connected layer
    disp('Input size to fully connected layer:');
    disp(size(input));
    disp('Weights size in fully connected layer:');
    disp(size(weights));
    disp('Biases size in fully connected layer:');
    disp(size(biases));
    
    output = weights * input + biases;
end