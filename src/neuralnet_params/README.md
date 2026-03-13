This folder contains all parameters necessary to initialize the neuralnet applied in place of GM and to do inference with it.

Each layer_* file contains the value for one network layer, 2 being the output layer.

*nlayers.bin*: single integer
*nneurons.bin*: array of integers with length nlayers

*normalization_params.bin*: Array with shape (n_features, 2) containing mean and standard deviation that was used to normalize each input feature during training. Is applied before inference.