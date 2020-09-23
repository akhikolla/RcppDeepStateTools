##' @title  creates Eclipser fuzzer for given functions in package
##' @export
deepstate_make_eclipser <- function(){
  insts.path <- "~"
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/SoftSec-KAIST/Eclipser && cd Eclipser && make"))
  master <- file.path(deepstate.path,"deepstate-master")
  #build_eclipser <- file.path(master,"build_eclipser")
  system(paste0("export ECLIPSER_HOME=",deepstate.path,"/Eclipser/build"))
}
