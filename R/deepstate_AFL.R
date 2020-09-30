##' @title  creates afl fuzzer for given functions in package
##' @export
deepstate_make_afl<-function(){
  #insts.path <- system.file(package="RcppDeepState")
  insts.path <- "~"
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  #dir.create(deepstate.path,showWarnings = FALSE)
  master <- file.path(deepstate.path,"deepstate-master")
  #afl <- file.path(deepstate.path,"AFL-master")
  system(paste0("cd ", insts.path, " ; "," wget http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz && tar -xzvf afl-latest.tgz && rm -rf afl-latest.tgz && cd afl-2.52b",";", "make"))
  build_afl <- file.path(master,"build_afl")
  dir.create(build_afl,showWarnings = FALSE)
  system("export AFL_HOME=\"~/afl-2.52b\"")
  #AFL_HOME <-"\"~/afl-2.52b\""
  system(paste0("cd ", build_afl," ; ","CXX=\"$AFL_HOME\afl-clang++\" CC=\"$AFL_HOME/afl-clang\" cmake -DDEEPSTATE_AFL=ON ../"," ; ", "make -j4"))
}





