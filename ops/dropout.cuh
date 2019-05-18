#ifndef BERT_CUDA_DROPOUT
#define BERT_CUDA_DROPOUT

#include "op_kernel.cuh"
#include <cudnn.h>

#define checkCUDNN(expression)                               \
  {                                                          \
    cudnnStatus_t status = (expression);                     \
    if (status != CUDNN_STATUS_SUCCESS) {                    \
      std::cerr << "cuDNN Error in File " << __FILE__ <<     \
     " Error on line " << __LINE__ << ": "                   \
      << cudnnGetErrorString(status) << std::endl;           \
      std::exit(EXIT_FAILURE);                               \
    }                                                        \
  }

class op_Dropout : public op_kernel {

public:
    cudnnHandle_t cudnn;
    cudnnDropoutDescriptor_t dropout_desc_;
    size_t states_size_in_bytes_;
    size_t reserve_space_size_in_bytes_;

    cudnnTensorDescriptor_t data_desc_;

    float dropRate;
    int n;
    float *grad_input;  // grad
    void *states_data;
    void *dropout_reserve_space;

public:
    op_Dropout(float dropR, global_handle *handle) :
            dropRate(dropR), op_kernel(handle) {

        //TODO
        checkCUDNN(cudnnCreate(&cudnn));
        checkCUDNN(cudnnCreateDropoutDescriptor(&dropout_desc_));
        checkCUDNN(cudnnCreateTensorDescriptor(&data_desc_));

        std::cout << "states_size_in_bytes_: " << states_size_in_bytes_ << std::endl;
        checkCUDNN(cudnnDropoutGetStatesSize(cudnn,
                                             &states_size_in_bytes_));
        std::cout << "states_size_in_bytes_: " << states_size_in_bytes_ << std::endl;

//        cudaMalloc(&states_data, states_size_in_bytes_);
//        cudaMalloc(&dropout_reserve_space_data, dropout_reserve_size);

        states_data = handle->global_malloc_manage_float.get_new_head_point(states_size_in_bytes_);
//        cudaMalloc(&states_data, states_size_in_bytes_);

        std::cout << "states_data: " << states_data << std::endl;
        std::cout << "dropout_desc_: " << dropout_desc_ << std::endl;
        std::cout << "cudnn: " << cudnn << std::endl;
        std::cout << "dropRate: " << dropRate << std::endl;
        checkCUDNN(cudnnSetDropoutDescriptor(dropout_desc_,
                                  cudnn,
                                  dropRate,
                                  states_data,
                                  states_size_in_bytes_,
                /*Seed*/1));
        std::cout << "PPPPPP" << std::endl;
    };

    template<typename T>
    void forward(T *&output, T *input, int len);

    template<typename T>
    void backward(T *dout);
};

#endif