version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs

workflow Sample {
    input {
        Sample sample
        String outputDir
        GeneralInput generalInput
    }

    scatter (library in sample.libraries) {
        call libraryWorkflow.Library as libraryWorkflow {
            input:
                generalInput = generalInput,
                outputDir = outputDir + "/lib_" + library.id,
                sample = sample,
                library = library
            }
        }

    output {

    }
}