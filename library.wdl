import "readgroup.wdl" as readgroup
import "tasks/biopet.wdl" as biopet
import "tasks/picard.wdl" as picard
import "tasks/samtools.wdl" as samtools

workflow library {
    Array[File] sampleConfigs
    String sampleId
    String libraryId
    String outputDir
    File refFasta
    File refDict
    File refFastaIndex

    call biopet.SampleConfig as readgroupConfigs {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            library = libraryId,
            tsvOutputPath = outputDir + "/" + libraryId + ".config.tsv",
            keyFilePath = outputDir + "/" + libraryId + ".config.keys"
    }

    scatter (rg in read_lines(readgroupConfigs.keysFile)) {
        if (rg != "") {
            call readgroup.readgroup as readgroup {
                input:
                    outputDir = outputDir + "/rg_" + rg,
                    sampleConfigs = sampleConfigs,
                    readgroupId = rg,
                    libraryId = libraryId,
                    sampleId = sampleId
            }
        }
    }

    call picard.MarkDuplicates as markdup {
        input:
            input_bams = readgroup.bamFile,
            output_bam_path = outputDir + "/" + sampleId + "-" + libraryId + ".markdup.bam",
            metrics_path = outputDir + "/" + sampleId + "-" + libraryId + ".markdup.metrics"
    }

    call samtools.Flagstat as flagstat {
        input:
            inputBam = markdup.output_bam,
            outputPath = outputDir + "/" + sampleId + "-" + libraryId + ".markdup.flagstat"
    }

    output {
        Array[String] readgroups = read_lines(readgroupConfigs.keysFile)
        File bamFile = markdup.output_bam
        File bamIndexFile = markdup.output_bam_index
    }
}
