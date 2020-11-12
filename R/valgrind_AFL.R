##' @title  run afl on all the packages
##' @param path to the package to test
##' @export
run_AFL<-function(){
  packages <- file.path(system.file("extdata",package="RcppDeepState"),"packages")
  cA.dir <- file.path(system.file("extdata",package="RcppDeepState"),"compileAttributes")
  root.path <- system.file("extdata",package="RcppDeepState")
  packages <- Sys.glob(file.path(cA.dir,"*"))
  for(pkg.i in seq_along(packages)){
    pkg.tar.gz <- packages[[pkg.i]]
  testfiles.vec <- Sys.glob(file.path(pkg.tar.gz,"inst/testfiles/*"))
  cat(sprintf("%4d - %s\n", pkg.i, pkg.tar.gz))
  if(length(testfiles.vec) > 0){
    deepstate_pkg_create_AFL(pkg.tar.gz)
  }
  }
}
