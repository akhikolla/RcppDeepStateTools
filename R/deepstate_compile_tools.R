##' @title  creates afl fuzzer for given functions in package
##' @param path to the package to test
##' @export
deepstate_compile_tools<-function(path){
  option=readline(prompt="Please choose an option to select the Fuzzer:\n1 - AFL\n2 - LibFuzzer\n3 - Eclipser\n4 - Angora\n5 - HonggFuzz")
  insts.path <- "~"
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if((file.exists("~/.RcppDeepState/deepstate-master/build/libdeepstate32.a") &&
      file.exists("~/.RcppDeepState/deepstate-master/build/libdeepstate.a"))){
    RcppDeepState::deepstate_make_run()
  }
  if(option == 1){
    deepstate.path <- paste0(insts.path,"/.RcppDeepState")
      if(!file.exists("~/.RcppDeepState/deepstate-master/build_afl/libdeepstate_AFL.a")){
        deepstate_make_afl()
      }
      inst_path <- file.path(path, "inst")
      test_path <- file.path(inst_path,"testfiles")
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
            logfile <-  paste0(function.path,"/afl_",f,"_log")
            output_dir <- paste0(function.path,"/afl_",f,"_output")
           makefile_lines <- readLines(makefile.path,warn=FALSE)
           makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("-ldeepstate","-ldeepstate_AFL",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_afl",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("R_HOME=","export AFL_HOME=~/afl-2.52b\nCXX = ${AFL_HOME}/afl-clang++\nAFL_FUZZ=${AFL_HOME}/afl-fuzz\nR_HOME=",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(executable,paste0(executable,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${AFL_HOME}/afl-fuzz -o ",output_dir," -m 150 -t 2000 -i ~/.RcppDeepState/deepstate-master/build_afl/ -- ",executable,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
           makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".afl"),makefile_lines,fixed=TRUE)
          makefile.afl <- file.path(dirname(makefile.path),"AFL.Makefile")
        file.create(makefile.afl,recursive=TRUE)
        cat(makefile_lines, file=makefile.afl, sep="\n")
        file.remove(object)
        file.remove(executable)
        compile_line <-paste0("rm -f *.o && make -f ",makefile.afl)
        print(compile_line)
        system(compile_line)
      }
    }
  }else if(option == 2){
    print("LibFuzzer")
  }else if(option == 3){
    print("Eclipser")
  }else if(option == 4){
    print("Angora")
  }else if(option == 5){
    deepstate.path <- paste0(insts.path,"/.RcppDeepState")
      if(!file.exists("~/.RcppDeepState/deepstate-master/build_afl/libdeepstate_HFUZZ.a")){
        deepstate_make__hongg()
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
        logfile <-  paste0(function.path,"/hongg_",f,"_log")
        output_dir <- paste0(function.path,"/hongg_",f,"_output")
        makefile_lines <- readLines(makefile.path,warn=FALSE)
        makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("-ldeepstate","-ldeepstate_HFUZZ",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_honggfuzz",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("R_HOME=","export HONGGFUZZ_HOME=~/honggfuzz\nCXX = ${HONGGFUZZ_HOME}/hfuzz_cc/hfuzz-clang++\nHONGG_FUZZ=${HONGGFUZZ_HOME}/hfuzz-8bitcnt-clang++ \nR_HOME=",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(executable,paste0(executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${HONGGFUZZ_HOME}/hfuzz-8bitcnt-clang++ -o ",output_dir," -m 150 -t 2000 -i ~/.RcppDeepState/deepstate-master/build_hongg/ -- ",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
        makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile.hongg <- file.path(dirname(makefile.path),"Hongg.Makefile")
        file.create(makefile.hongg,recursive=TRUE)
        cat(makefile_lines, file=makefile.hongg, sep="\n")
        file.remove(object)
        file.remove(executable)
        compile_line <-paste0("rm -f *.o && make -f ",makefile.hongg)
        #print(compile_line)
        system(compile_line)
      }
    }
  }
}
