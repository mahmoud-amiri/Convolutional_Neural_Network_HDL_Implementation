function output = convolutionLayer(input, filter, stride, padding)
    % Get dimensions of the input and filter
    [inputHeight, inputWidth, inputDepth] = size(input);
    [filterHeight, filterWidth, filterDepth, numFilters] = size(filter);

    % Calculate dimensions of the output
    outputHeight = (inputHeight - filterHeight + 2 * padding) / stride + 1;
    outputWidth = (inputWidth - filterWidth + 2 * padding) / stride + 1;

    % Initialize the output
    output = zeros(outputHeight, outputWidth, numFilters);

    % Pad the input if necessary
    if padding > 0
        input = padarray(input, [padding, padding]);
    end

    % Perform the convolution
    for f = 1:numFilters
        for i = 1:stride:(inputHeight - filterHeight + 1)
            for j = 1:stride:(inputWidth - filterWidth + 1)
                % Extract the current region
                region = input(i:(i + filterHeight - 1), j:(j + filterWidth - 1), :);

                % Element-wise multiplication and sum
                outputValue = sum(region .* filter(:, :, :, f), 'all');

                % Calculate the position in the output matrix
                outputRow = (i - 1) / stride + 1;
                outputCol = (j - 1) / stride + 1;

                % Assign the calculated value to the output matrix
                output(outputRow, outputCol, f) = outputValue;
            end
        end
    end
end
