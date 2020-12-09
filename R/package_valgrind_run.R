valgrind_afl_test <- function(pkg.tar.gz){
 #install.packages(setdiff(basename(pkg.tar.gz), rownames(installed.packages())))
  #install.packages(basename(pkg.tar.gz))
  #system(paste0("R CMD INSTALL ",basename(pkg.tar.gz)))
  if(length(setdiff(basename(pkg.tar.gz), rownames(installed.packages()))) == 0){
    testfiles.vec <- Sys.glob(file.path(pkg.tar.gz,"inst/testfiles/*"))
    test_path <- file.path(pkg.tar.gz,"inst/testfiles")
    functions.list <-  RcppDeepState::deepstate_get_function_body(pkg.tar.gz)
    cat(sprintf("%s\n", pkg.tar.gz))
    if(length(testfiles.vec) > 0){
      for(fun in testfiles.vec){
        afl.fun.path <- file.path(test_path,basename(fun),paste0("AFL_",basename(fun)))
        afl.inputs <- Sys.glob(file.path(afl.fun.path,"afl_inputs/*"))
        afl.inputs.path <- file.path(afl.fun.path,"afl_inputs")
        times <- unique(gsub("_.*","",basename(afl.inputs)))
for(utime in times){
  run_line <- paste0("R -d \"valgrind --xml=yes --xml-file=",file.path(afl.inputs.path,paste0(utime,"_valgrind_log"))," --tool=memcheck --leak-check=yes\" --vanilla --args ",afl.inputs.path,"/",utime," < /home/akhila/RcppDeepStateTest/afl_valgrind_per_function.R")
  print(run_line)
  if(!file.exists(file.path(afl.inputs.path,paste0(utime,"_valgrind_log")))){
  system(run_line)
  print("valgrind result")
  result = RcppDeepState::deepstate_read_valgrind_xml(file.path(afl.inputs.path,paste0(utime,"_valgrind_log")))
  print(result$logtable)
}
}
}
}
}
}
