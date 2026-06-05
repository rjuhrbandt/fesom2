This folder contains all parameters necessary to initialize the neuralnet applied in place of GM and to do inference with it.

Each layer_* file contains the value for one network layer, 2 being the output layer.

*nlayers.bin*: single integer
*nneurons.bin*: array of integers with length nlayers

*input_normalization_params.bin*: Array with shape (n_features, 2) containing mean and standard deviation that was used to normalize each input feature during training. Is applied before inference.

*output_normalization_full.bin*: Array with shape (3,2) containing mean and standard deviation that was used for the first normalization step during preprocessing of outputs for neuralnet training.

*output_normalization_train.bin*: Array with shape (3,2) containing mean and standard deviation that was used for the second normalization step during preprocessing of outputs for neuralnet training.

*Further clarification for normalization of outputs*:
Horizontal and vertical fluxes have different orders of magnitude. Max/min of horizontal fluxes: O(1), max/min of vertical fluxes: O(1e-3). 