version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs
import "tasks/macs2.wdl" as macs2

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

        File bamFiles = libraryWorkflow.bamFile.file
        File indexFiles = libraryWorkflow.bamFile.index
    }

    call macs2.PeakCalling as peakcalling {
        input:
            inputBams = bamFiles,
            inputBamsIndex = indexFiles,
            outDir = outputDir + "/macs2",
            sampleName = sample.id
    }

    output {
        File peakFile = peakcalling.peakFile
    }
}
