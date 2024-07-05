function output = maxPoolingLayer(input, poolSize, stride)
    % Get dimensions of the input
    [inputHeight, inputWidth] = size(input);

    % Calculate dimensions of the output
    outputHeight = floor((inputHeight - poolSize) / stride) + 1;
    outputWidth = floor((inputWidth - poolSize) / stride) + 1;

    % Initialize the output
    output = zeros(outputHeight, outputWidth);

    % Perform max pooling
    for i = 1:stride:(inputHeight - poolSize + 1)
        for j = 1:stride:(inputWidth - poolSize + 1)
            % Extract the current region
            region = input(i:(i + poolSize - 1), j:(j + poolSize - 1));

            % Find the maximum value in the region
            maxValue = max(region(:));

            % Calculate the position in the output matrix
            outputRow = (i - 1) / stride + 1;
            outputCol = (j - 1) / stride + 1;

            % Assign the max value to the output matrix
            output(outputRow, outputCol) = maxValue;
        end
    end
end