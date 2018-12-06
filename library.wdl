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
        Int MAPQthreshold
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
        File readgroupBamFiles = readgroupWorkflow.bamFile.file
        File readgroupBamIndexes = readgroupWorkflow.bamFile.index
    }

    call picard.MarkDuplicates as markdup {
        input:
            inputBams = readgroupBamFiles,
            inputBamIndexes = readgroupBamIndexes,
            outputBamPath = outputDir + "/" + sample.id + "-" + library.id + ".markdup.bam",
            metricsPath = outputDir + "/" + sample.id + "-" + library.id + ".markdup.metrics"
    }

    call bammetrics.BamMetrics as BamMetrics {
        input:
            bam = markdup.outputBam,
            outputDir = outputDir + "/metrics",
            reference = chipSeqInput.reference
    }

    call samtools.View as filterBam {
    ## Remove reads unmapped, mate unmapped, not primary alignment, reads failing platform, duplicates (using
    ## excludeFilter)
    ## Remove multi-mapped reads (with MAPQthreshlod)
        input:
            inFile = markdup.outputBam.file,
            outputFileName = outputDir + "/" + sample.id + "-" + library.id + ".filtered.bam",
            excludeFilter = 1804,
            MAPQthreshold = MAPQthreshold
    }

    call samtools.Index as indexFilterBam {
        input:
            bamFile = filterBam.outputFile,
            bamIndexPath =  outputDir + "/" + sample.id + "-" + library.id + ".filtered.bai",
    }

    call bammetrics.BamMetrics as BamMetricsAfterFilter {
        input:
            bam = filterBam.outputFile.file,
            outputDir = outputDir + "/metricsAfterFilter",
            reference = chipSeqInput.reference
    }

    output {
        IndexedBamFile bamFile = indexFilterBam.outputBam
    }
}
