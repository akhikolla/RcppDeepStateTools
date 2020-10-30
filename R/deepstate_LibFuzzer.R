##' @title  creates LibFuzzer specific make files for given functions in package
##' @param path to the package to test
##' @export
deepstate_pkg_create_LibFuzzer<-function(path){
  path <- normalizePath(path,mustWork=TRUE)
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate <- file.path(insts.path,".RcppDeepState")
  deepstate.path <- file.path(deepstate,"deepstate-master")
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if(!(file.exists(file.path(insts.path,".RcppDeepState/deepstate-master/build/libdeepstate32.a")) &&
       file.exists(file.path(insts.path,"/.RcppDeepState/deepstate-master/build/libdeepstate.a")))){
    RcppDeepState::deepstate_make_run()
  }
  LF.a <- file.path(deepstate.path,"build_libfuzzer/libdeepstate_LF.a")
  if(!file.exists(LF.a)){
    deepstate_make_libFuzzer()
    #print("lib not exists")
  }
  functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
  fun_names <- unique(functions.list$funName)
  for(f in fun_names){
    function.path <- file.path(test_path,f)
    harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
    makefile.path <- file.path(function.path,"Makefile")
    if(file.exists(harness.path) && file.exists(makefile.path) ){
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      o.logfile <- paste0(function.path,"/",f,"_log")
      logfile <-  paste0(function.path,"/libfuzzer_",f,"_log")
      output_dir <- paste0(function.path,"/libfuzzer_",f,"_output")
      makefile_lines <- readLines(makefile.path,warn=FALSE)
      makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,"_LF"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("clang++ -g","clang++ -g -fsanitize=address,fuzzer",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("-ldeepstate","-ldeepstate -ldeepstate_LF",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_libfuzzer",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(executable,paste0(executable,"_LF"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("./",basename(executable),"_LF"," --fuzz"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
      makefile_lines <- gsub("valgrind.* ./","./",makefile_lines)
      makefile_lines <- gsub("_LF.cpp",".cpp",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,"_LF"),makefile_lines,fixed=TRUE)
      makefile.libfuzzer <- file.path(dirname(makefile.path),"libfuzz.Makefile")
      file.create(makefile.libfuzzer,recursive=TRUE)
      cat(makefile_lines, file=makefile.libfuzzer, sep="\n")
      #file.remove(object)
      #file.remove(executable)
      compile_line <-paste0("rm -f *.o && make -f ",makefile.libfuzzer)
      print(compile_line)
      system(compile_line)
    }
  }

}


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
