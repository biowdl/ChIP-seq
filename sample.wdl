version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs
import "tasks/bwa.wdl" as bwa

workflow Sample {
    input {
        Sample sample
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
        BwaIndex bwaIndex
    }

    scatter (library in sample.libraries) {
        call libraryWorkflow.Library as libraryWorkflow {
            input:
                refFasta = refFasta,
                refDict = refDict,
                refFastaIndex = refFastaIndex,
                outputDir = outputDir + "/lib_" + library.id,
                sample = sample,
                library = library,
                bwaIndex = bwaIndex
            }
        }

    output {

    }
}