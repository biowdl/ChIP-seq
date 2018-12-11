version 1.0

import "library.wdl" as libraryWorkflow
import "structs.wdl" as structs
import "tasks/common.wdl" as common
import "tasks/samtools.wdl" as samtools
import "tasks/bedtools.wdl" as bedtools

workflow Sample {
    input {
        Sample sample
        String outputDir
        ChipSeqInput chipSeqInput
        Int MAPQthreshold
    }

    scatter (library in sample.libraries) {
        call libraryWorkflow.Library as libraryWorkflow {
            input:
                chipSeqInput = chipSeqInput,
                outputDir = outputDir + "/lib_" + library.id,
                sample = sample,
                library = library,
                MAPQthreshold = MAPQthreshold
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

    ## Bamtobed call is different for SE and PE datasets
    if (defined(sample.libraries[0].readgroups[0].reads.R2)) {
        call bedtools.Bamtobed as peBamtobed {
            input:
                inputBam = mergeBams.outputBam,
                bedpe = true,
                mate1 = true,
                bedPath = outputDir + "/" + sample.id + ".bedpe"
        }
    }

    if (!defined(sample.libraries[0].readgroups[0].reads.R2)) {
        call bedtools.Bamtobed as seBamtobed {
            input:
                inputBam = mergeBams.outputBam,
                bedPath = outputDir + "/" + sample.id + ".bed"
        }
    }

    output {
        IndexedBamFile bamFile = indexBams.outputBam
        ## One of the peBamtobed or seBamtobed will be called
        File bedFile = select_first([peBamtobed.outputBed, seBamtobed.outputBed])
    }
}
