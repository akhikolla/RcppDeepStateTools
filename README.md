# RcppDeepStateTools

RcppDeepStateTools will be a Linux-specific R package, with R functions for running the DeepState test harness (src/RcppDeepState.cpp) using different back-end fuzz testers or symbolic execution libraries.

## Installation

The RcppDeepStateTools package can be installed from GitHub as follows:

```R
install_github("akhikolla/RcppDeepStateTools")
```

(a) **deepstate_compile_tools**: This function helps us fuzz test your Rcpp package using one of the back end fuzzers. Please choose the options to select the tool.

```R
RcppDeepState::deepstate_compile_tools()
```

Please choose an option to select the Fuzzer:
1 - AFL
2 - LibFuzzer
3 - Eclipser
4 - Angora
5 - HonggFuzz

