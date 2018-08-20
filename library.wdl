version 1.0

import "readgroup.wdl" as readgroup
import "tasks/picard.wdl" as picard
import "tasks/samtools.wdl" as samtools
import "structs.wdl" as structs

workflow library {
    input{
        Sample sample
        Library library
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
    }

    scatter (rg in library.readgroups) {
        call readgroupWorkflow.readgroup as readgroupWorkflow {
            input:
                outputDir = outputDir + "/rg_" + readgroup.id,
                readgroup = readgroup
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
