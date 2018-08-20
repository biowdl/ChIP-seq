version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs

workflow sample {
    input {
        Sample sample
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
    }

    scatter (library in sample.libraries) {
        call libraryWorkflow.library as libraryWorkflow {
            input:
                outputDir = outputDir + "/lib_" + library.id,
                library = library
            }
        }

    output {

    }
}