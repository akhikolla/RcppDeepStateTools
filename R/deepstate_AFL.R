##' @title  creates afl fuzzer for given functions in package
##' @export
deepstate_make_afl<-function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  system(paste0("cd ", deepstate.path, " ; "," wget http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz && tar -xzvf afl-latest.tgz && rm -rf afl-latest.tgz && cd afl-2.52b",";", "make"))
  build_afl <- file.path(master,"build_afl")
  dir.create(build_afl,showWarnings = FALSE)
  AFL_HOME = file.path(deepstate.path,"afl-2.52b")
  Sys.setenv(AFL_HOME=AFL_HOME)
  system(paste0("cd ", build_afl," ; ","CXX=",AFL_HOME,"/afl-clang++ " ,"CC=", AFL_HOME,"/afl-clang cmake -DDEEPSTATE_AFL=ON ../"," ; ", "make -j4"))
}





