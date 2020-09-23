##' @title  creates Angora fuzzer for given functions in package
##' @export
deepstate_make_angora <- function(){
  insts.path <- "~"
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/AngoraFuzzer/Angora && cd Angora && ./build/build.sh"))
  master <- file.path(deepstate.path,"deepstate-master")
  build_angora <- file.path(master,"build_angora")
  dir.create(build_angora,showWarnings = FALSE)
  system("export PATH=\"/clang+llvm/bin:$PATH\"")
  system("export LD_LIBRARY_PATH=\"/clang+llvm/lib:$LD_LIBRARY_PATH\"")
  system("export ANGORA_HOME=\"/angora\"")
  system(paste0("cd ", build_angora," ; ","CXX=\"$ANGORA_HOME/bin/angora-clang++\" CC=\"$ANGORA_HOME/bin/angora-clang\" cmake -DDEEPSTATE_ANGORA=ON ../"," ; ", "make"))
}
