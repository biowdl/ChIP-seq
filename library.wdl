version 1.0

import "readgroup.wdl" as readgroupWorkflow
import "tasks/picard.wdl" as picard
import "tasks/samtools.wdl" as samtools
import "structs.wdl" as structs
import "tasks/bwa.wdl" as bwa

workflow Library {
    input {
        Sample sample
        Library library
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
        BwaIndex bwaIndex
    }

    scatter (rg in library.readgroups) {
        call readgroupWorkflow.Readgroup as readgroupWorkflow {
            input:
                refFasta = refFasta,
                refDict = refDict,
                refFastaIndex = refFastaIndex,
                outputDir = outputDir + "/rg_" + rg.id,
                sample = sample,
                library = library,
                readgroup = rg,
                bwaIndex = bwaIndex
        }
    }

    call picard.MarkDuplicates as markdup {
        input:
            input_bams = readgroupWorkflow.bamFile,
            output_bam_path = outputDir + "/" + sample.id + "-" + library.id + ".markdup.bam",
            metrics_path = outputDir + "/" + sample.id + "-" + library.id + ".markdup.metrics"
    }

    call samtools.Flagstat as flagstat {
        input:
            inputBam = markdup.output_bam,
            outputPath = outputDir + "/" + sample.id + "-" + library.id + ".markdup.flagstat"
    }

    output {
        File bamFile = markdup.output_bam
        File bamIndexFile = markdup.output_bam_index
    }
}
