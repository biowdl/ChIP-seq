version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs

workflow Sample {
    input {
        Sample sample
        String outputDir
        ChipSeqInput chipSeqInput
    }

    scatter (library in sample.libraries) {
        call libraryWorkflow.Library as libraryWorkflow {
            input:
                chipSeqInput = chipSeqInput,
                outputDir = outputDir + "/lib_" + library.id,
                sample = sample,
                library = library
            }
        }

    output {

    }
}