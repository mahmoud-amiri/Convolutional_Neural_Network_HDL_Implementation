function paddedImage = padarray(input, padSize)
    % Get the dimensions of the input
    [inputHeight, inputWidth, inputDepth] = size(input);

    % Calculate the dimensions of the padded image
    paddedHeight = inputHeight + 2 * padSize(1);
    paddedWidth = inputWidth + 2 * padSize(2);
    paddedDepth = inputDepth;

    % Initialize the padded image with zeros
    paddedImage = zeros(paddedHeight, paddedWidth, paddedDepth);

    % Copy the original image into the center of the padded image
    paddedImage(padSize(1) + 1:end - padSize(1), padSize(2) + 1:end - padSize(2), :) = input;
end
