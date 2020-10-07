##' @title  creates Hongg fuzzer for given functions in package
##' @export
deepstate_make__hongg <- function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  build_honggfuzz <- file.path(master,"build_honggfuzz")
  dir.create(build_honggfuzz,showWarnings = FALSE)
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/google/honggfuzz && cd honggfuzz && make"))
  HONGGFUZZ_HOME = file.path(deepstate.path,"honggfuzz")
  Sys.setenv(HONGGFUZZ_HOME=HONGGFUZZ_HOME)
  system(paste0("cd ", build_honggfuzz," ; ","CXX=",HONGGFUZZ_HOME,"/hfuzz_cc/hfuzz-clang++",
                " CC=",HONGGFUZZ_HOME,"/hfuzz_cc/hfuzz-clang\" cmake -DDEEPSTATE_HONGGFUZZ=ON ../"," ; ", "make"))

}
