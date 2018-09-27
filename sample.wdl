version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs
import "tasks/common.wdl" as common
import "tasks/samtools.wdl" as samtools


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

        File bam = libraryWorkflow.bamFile.file
    }


    call samtools.Merge as mergeBams {
        input:
            bamFiles = bam,
            outputBamPath = outputDir + "/" + sample.id + ".bam"
    }

    call samtools.Index as indexBams {
        input:
            bamFile = mergeBams.outputBam,
            bamIndexPath = outputDir + "/" + sample.id + ".bai"
    }

    output {
        IndexedBamFile bamFile = indexBams.outputBam
    }
}
