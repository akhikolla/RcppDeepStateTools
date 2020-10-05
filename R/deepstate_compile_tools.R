##' @title  creates afl fuzzer for given functions in package
##' @param path to the package to test
##' @export
deepstate_compile_tools<-function(path){
  option=readline(prompt="Please choose an option to select the Fuzzer:\n1 - AFL\n2 - LibFuzzer\n3 - Eclipser\n4 - Angora\n5 - HonggFuzz")
  insts.path <- "~"
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if(!(file.exists("~/.RcppDeepState/deepstate-master/build/libdeepstate32.a") &&
      file.exists("~/.RcppDeepState/deepstate-master/build/libdeepstate.a"))){
    RcppDeepState::deepstate_make_run()
  }
  if(option == 1){
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
    if(!file.exists("~/.RcppDeepState/deepstate-master/build_libfuzzer/libdeepstate_LF.a")){
      #deepstate_make_libFuzzer()
      print("lib not exists")
    }
    system("export ECLIPSER_HOME= ~/.RcppDeepState/deepstate-master/Eclipser/build ")
    functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
    fun_names <- unique(functions.list$funName)
    for(f in fun_names){
      function.path <- file.path(test_path,f)
      harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
      makefile.path <- file.path(function.path,"Makefile")
      if(file.exists(harness.path) && file.exists(makefile.path) ){
        executable <- gsub(".cpp$","",harness.path)
        object <- gsub(".cpp$",".o",harness.path)
        object_LF <- gsub(".o$","_LF.o",object)
        #print(object_LF)
        o.logfile <- paste0(function.path,"/",f,"_log")
        logfile <-  paste0(function.path,"/libfuzzer_",f,"_log")
        output_dir <- paste0(function.path,"/libfuzzer_",f,"_output")
        makefile_lines <- readLines(makefile.path,warn=FALSE)
        makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,"_LF"),makefile_lines,fixed=TRUE)
        #makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("-ldeepstate","-ldeepstate -ldeepstate_LF",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_LF",makefile_lines,fixed=TRUE)
       #makefile_lines <- gsub("R_HOME1=","export HONGGFUZZ_HOME=~/honggfuzz\nCXX = ${HONGGFUZZ_HOME}/hfuzz_cc/hfuzz-clang++\nHONGG_FUZZ=${HONGGFUZZ_HOME}/hfuzz-8bitcnt-clang++ \nR_HOME=",makefile_lines,fixed=TRUE)
        #makefile_lines <- gsub(object,object_LF,makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(executable,paste0(executable,"_LF"),makefile_lines,fixed=TRUE)
        #makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("~/.RcppDeepState/deepstate-master/build_honggfuzz/honggfuzz/honggfuzz -o ",output_dir," -m 150 -t 2000 -i ~/.RcppDeepState/deepstate-master/build_hongg/ -- ",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
        makefile_lines <- gsub("_LF.cpp",".cpp",makefile_lines,fixed=TRUE)
        #makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,"_LF"),makefile_lines,fixed=TRUE)
        makefile.libfuzzer <- file.path(dirname(makefile.path),"libfuzz.Makefile")
        file.create(makefile.libfuzzer,recursive=TRUE)
        cat(makefile_lines, file=makefile.libfuzzer, sep="\n")
        #if exist
        #file.remove(object)
        #file.remove(executable)
        compile_line <-paste0("rm -f *.o && make -f ",makefile.libfuzzer)
        print(compile_line)
        #system(compile_line)
      }
    }

  }else if(option == 3){
    if(!file.exists("~/.RcppDeepState/deepstate-master/Eclipser/build/Eclipser.dll")){
      deepstate_make_eclipser()
      print("lib not exists")
    }
    functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
    fun_names <- unique(functions.list$funName)
    for(f in fun_names){
      function.path <- file.path(test_path,f)
      harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
      makefile.path <- file.path(function.path,"Makefile")
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      if(file.exists(harness.path) && file.exists(makefile.path) && file.exists(executable)){
        eclipser_out <- file.path(function.path,"eclipser_out")
        dir.create(eclipser_out,showWarnings = FALSE)
        compile_line <- paste0("cd ",function.path," && deepstate-eclipser ",basename(executable)," -o eclipser_out --timeout 30")
        print(compile_line)
      }
  }
}else if(option == 4){
    print("Angora")
  }else if(option == 5){
      if(!file.exists("~/.RcppDeepState/deepstate-master/build_honggfuzz/libdeepstate_HFUZZ.a")){
        #deepstate_make__hongg()
        print("lib not exists")
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
        #makefile_lines <- gsub(executable,paste0(executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("~/.RcppDeepState/deepstate-master/build_honggfuzz/honggfuzz/honggfuzz -o ",output_dir," -m 150 -t 2000 -i ~/.RcppDeepState/deepstate-master/build_hongg/ -- ",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
        makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile.hongg <- file.path(dirname(makefile.path),"Hongg.Makefile")
        file.create(makefile.hongg,recursive=TRUE)
        cat(makefile_lines, file=makefile.hongg, sep="\n")
        #if exist
        #file.remove(object)
        #file.remove(executable)
        compile_line <-paste0("rm -f *.o && make -f ",makefile.hongg)
        print(compile_line)
        system(compile_line)
      }
    }
  }
}
