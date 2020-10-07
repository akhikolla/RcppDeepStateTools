##' @title  creates Eclipser fuzzer for given functions in package
##' @export
deepstate_make_eclipser <- function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/SoftSec-KAIST/Eclipser && cd Eclipser && make"))
  ECLIPSER_HOME = file.path(deepstate.path,"Eclipser/build")
  Sys.setenv(ECLIPSER_HOME=ECLIPSER_HOME)
}
