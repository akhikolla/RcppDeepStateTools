##' @title  creates libfuzzer for given functions in package
##' @export
deepstate_make_libFuzzer <- function(){
  insts.path <- "~"
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  build_libfuzzer <- file.path(master,"build_libfuzzer")
  dir.create(build_libfuzzer,showWarnings = FALSE)
  system(paste0("cd ", build_libfuzzer," ; ","CXX=clang++ CC=clang cmake -DDEEPSTATE_LIBFUZZER=ON ../"," ; ", "make -j4"))
  system(paste0("cd ",build_libfuzzer," sudo cp ./libdeepstate_LF.a /usr/local/lib/"))
  }
