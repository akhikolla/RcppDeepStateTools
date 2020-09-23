##' @title  creates afl fuzzer for given functions in package
##' @param path to the package to test
##' @export
deepstate_compile_tools<-function(path){
  option=readline(prompt="Please choose an option to select the Fuzzer:\n1 - AFL\n2 - LibFuzzer\n3 - Eclipser\n4 - Angora\n5 - HonggFuzz")
  if(option == 1){
    insts.path <- "~"
    deepstate.path <- paste0(insts.path,"/.RcppDeepState")
    if((file.exists("~/.RcppDeepState/deepstate-master/build/libdeepstate32.a") &&
         file.exists("~/.RcppDeepState/deepstate-master/build/libdeepstate.a"))){
      if(!file.exists("~/.RcppDeepState/deepstate-master/build_afl/libdeepstate_AFL.a")){
        deepstate_make_afl()
      }
      }
    else{
        RcppDeepState::deepstate_make_run()
        deepstate_make_afl()
    }
    if(file.exists("~/.RcppDeepState/deepstate-master/build_afl/libdeepstate_AFL.a")){
      inst_path <- file.path(path, "inst")
      test_path <- file.path(inst_path,"testfiles")
      functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
      print(functions.list)
      fun_names <- unique(functions.list$funName)
      for(f in fun_names){
        function.path <- file.path(test_path,f)
        harness.path <- file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
        makefile.path <- file.path(function.path,"Makefile")
        if(file.exists(harness.path) && file.exists(makefile.path) )
            executable <- gsub(".cpp$","",harness.path)
            object <- gsub(".cpp$",".o",harness.path)
           makefile_lines <- readLines(makefile.path,warn=FALSE)
           makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("-ldeepstate","-ldeepstate_AFL",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_afl",makefile_lines,fixed=TRUE)
           makefile_lines <- gsub("R_HOME=","export AFL_HOME=~/.RcppDeepState/afl-2.52b\\nCXX = ${AFL_HOME}/afl-clang++\nR_HOME=",makefile_lines,fixed=TRUE)
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
    print("HonggFuzz")
  }

}
