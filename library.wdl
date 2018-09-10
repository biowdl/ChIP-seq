version 1.0

import "readgroup.wdl" as readgroupWorkflow
import "tasks/picard.wdl" as picard
import "tasks/samtools.wdl" as samtools
import "structs.wdl" as structs
import "BamMetrics/bammetrics.wdl" as bammetrics

workflow Library {
    input {
        Sample sample
        Library library
        String outputDir
        ChipSeqInput chipSeqInput
    }

    scatter (rg in library.readgroups) {
        call readgroupWorkflow.Readgroup as readgroupWorkflow {
            input:
                chipSeqInput = chipSeqInput,
                outputDir = outputDir + "/rg_" + rg.id,
                sample = sample,
                library = library,
                readgroup = rg
        }
    }

    call picard.MarkDuplicates as markdup {
        input:
            input_bams = readgroupWorkflow.bamFile,
            output_bam_path = outputDir + "/" + sample.id + "-" + library.id + ".markdup.bam",
            metrics_path = outputDir + "/" + sample.id + "-" + library.id + ".markdup.metrics"
    }

    call bammetrics.BamMetrics as BamMetrics {
        input:
            bamFile = markdup.output_bam,
            bamIndex = markdup.output_bam_index,
            outputDir = outputDir + "/metrics",
            refFasta = chipSeqInput.reference.fasta,
            refDict = chipSeqInput.reference.dict,
            refFastaIndex = chipSeqInput.reference.fai
    }

    output {
        File bamFile = markdup.output_bam
        File bamIndexFile = markdup.output_bam_index
    }
}
