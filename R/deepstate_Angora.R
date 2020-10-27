
##' @title  creates Angora fuzzer for given functions in package
##' @export
deepstate_make_angora <- function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- file.path(insts.path,".RcppDeepState")
  ANGORA_HOME<-file.path(deepstate.path,"Angora")
  Sys.setenv(ANGORA_HOME=ANGORA_HOME)
  if(!file.exists(ANGORA_HOME)){
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/AngoraFuzzer/Angora && cd Angora && ./build/build.sh"))
  }
  master <- file.path(deepstate.path,"deepstate-master")
  build_angora <- file.path(master,"build_angora_taint")
  dir.create(build_angora,showWarnings = FALSE)
  #Sys.setenv(PATH="/clang+llvm/bin:$PATH")
  #Sys.setenv(LD_LIBRARY_PATH="/clang+llvm/lib:$LD_LIBRARY_PATH")
  #system("export PATH=\"/clang+llvm/bin:$PATH\"")
  #system("export LD_LIBRARY_PATH=\"/clang+llvm/lib:$LD_LIBRARY_PATH\"")
  system(paste0("cd ", build_angora," ; ","CXX=",ANGORA_HOME,"/bin/angora-clang++ ","CC=",ANGORA_HOME,
                 "/bin/angora-clang cmake -DDEEPSTATE_ANGORA=ON ../"," ; ", "make -j4 -i "))
    }
