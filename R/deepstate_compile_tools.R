##' @title  creates afl fuzzer for given functions in package
##' @param path to the package to test
##' @export
deepstate_compile_tools<-function(path){
  path <- normalizePath(path,mustWork=TRUE)
  option=readline(prompt="Please choose an option to select the Fuzzer:\n1 - AFL\n2 - LibFuzzer\n3 - Eclipser\n4 - HonggFuzz")
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate <- paste0(insts.path,"/.RcppDeepState")
  deepstate.path <- file.path(deepstate,"deepstate-master")
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if(!(file.exists(paste0(insts.path,"/.RcppDeepState/deepstate-master/build/libdeepstate32.a")) &&
      file.exists(paste0(insts.path,"/.RcppDeepState/deepstate-master/build/libdeepstate.a")))){
    RcppDeepState::deepstate_make_run()
  }
  if(option == 1){
      AFL.a <- file.path(deepstate.path,"build_afl/libdeepstate_AFL.a")
      if(!file.exists(AFL.a)){
        deepstate_make_afl()
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
            logfile <-  paste0(function.path,"/afl_",f,"_log")
            output_dir <- paste0(function.path,"/afl_",f,"_output")
           makefile_lines <- readLines(makefile.path,warn=FALSE)
           makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("-ldeepstate","-ldeepstate_AFL",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_afl",makefile_lines,fixed=TRUE)
           AFL_HOME = file.path(deepstate,"afl-2.52b")
           Sys.setenv(AFL_HOME=AFL_HOME)
           makefile_lines <- gsub("R_HOME=",paste0("export AFL_HOME=",AFL_HOME,"\nCXX=${AFL_HOME}/afl-clang++\nAFL_FUZZ=${AFL_HOME}/afl-fuzz\nR_HOME="),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
           #makefile_lines <- gsub(object,paste0(object,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(executable,paste0(executable,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${AFL_HOME}/afl-fuzz -o ",output_dir," -m 150 -t 2000 -i ~/.RcppDeepState/deepstate-master/build_afl/ -- ",executable,".afl"),makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
           makefile_lines <- gsub(".afl.cpp",".cpp",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".afl"),makefile_lines,fixed=TRUE)
          makefile.afl <- file.path(dirname(makefile.path),"AFL.Makefile")
        file.create(makefile.afl,recursive=TRUE)
        cat(makefile_lines, file=makefile.afl, sep="\n")
        #file.remove(object)
        #file.remove(executable)
        compile_line <-paste0("rm -f *.o && make -f ",makefile.afl)
        print(compile_line)
        system(compile_line)
      }
    }
  }else if(option == 2){
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
        makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_LF",makefile_lines,fixed=TRUE)
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

  }else if(option == 3){
    dll <- file.path(deepstate,"Eclipser/build/Eclipser.dll")
    if(!file.exists(dll)){
      deepstate_make_eclipser()
    }
    functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
    fun_names <- unique(functions.list$funName)
    for(f in fun_names){
      function.path <- file.path(test_path,f)
      harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
      makefile.path <- file.path(function.path,"Makefile")
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      o.logfile <- paste0(function.path,"/",f,"_log")
      logfile <-  paste0(function.path,"/eclipser_",f,"_log")
      if(file.exists(harness.path) && file.exists(makefile.path) && file.exists(executable)){
        eclipser_out <- file.path(function.path,"eclipser_out")
        dir.create(eclipser_out,showWarnings = FALSE)
        #compile_line <- paste0("cd ",function.path," && deepstate-eclipser ./",basename(executable)," -o eclipser_out --timeout 30")
        executable <- gsub(".cpp$","",harness.path)
        object <- gsub(".cpp$",".o",harness.path)
        o.logfile <- paste0(function.path,"/",f,"_log")
        makefile_lines <- readLines(makefile.path,warn=FALSE)
        makefile_lines <- gsub("R_HOME=",paste0("export ECLIPSER_HOME=",insts.path,"/.RcppDeepState/Eclipser/build\nR_HOME="),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
        makefile_lines <- gsub("valgrind.* ./","./",makefile_lines)
        makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("deepstate-eclipser ./",basename(executable)," -o eclipser_out --timeout 30"),makefile_lines,fixed=TRUE)
        makefile.eclipser <- file.path(dirname(makefile.path),"Eclipser.Makefile")
        file.create(makefile.eclipser,recursive=TRUE)
        cat(makefile_lines, file=makefile.eclipser, sep="\n")
        compile_line <-paste0("rm -f *.o && make -f ",makefile.eclipser)
        print(compile_line)
        system(compile_line)
      }
  }
}else if(option == 4){
      HF.a <- file.path(deepstate.path,"build_honggfuzz/libdeepstate_HFUZZ.a")
      if(!file.exists(HF.a)){
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
        input_dir <- paste0(function.path,"/",f,"_output")
        makefile_lines <- readLines(makefile.path,warn=FALSE)
        makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("-ldeepstate","-ldeepstate_HFUZZ",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_honggfuzz",makefile_lines,fixed=TRUE)
        HONGGFUZZ_HOME = file.path(deepstate,"honggfuzz")
        Sys.setenv(HONGGFUZZ_HOME=HONGGFUZZ_HOME)
        makefile_lines <- gsub("R_HOME=",paste0("export HONGGFUZZ_HOME=",HONGGFUZZ_HOME,"\nCXX = ${HONGGFUZZ_HOME}/hfuzz_cc/hfuzz-clang++\nHONGG_FUZZ=${HONGGFUZZ_HOME}/honggfuzz \nR_HOME="),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(executable,paste0(executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${HONGGFUZZ_HOME}/honggfuzz -t 2000 -i ",input_dir," -o ",output_dir," -x -- ",executable,".hongg"," ___FILE___"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
        makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".hongg"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(".hongg.cpp",".cpp",makefile_lines,fixed=TRUE)
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
  else if(option == 5){
    print("Angora")
  }
}
