version 1.0

import "QC/AdapterClipping.wdl" as adapterClipping
import "QC/QualityReport.wdl" as qualityReport
import "aligning/align-bwamem.wdl" as wdlMapping
import "tasks/biopet.wdl" as biopet

workflow readgroup {
    input {
        Array[File] sampleConfigs
        String readgroupId
        String libraryId
        String sampleId
        String outputDir
    }

    call biopet.SampleConfig as config {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId,
            tsvOutputPath = outputDir + "/" + readgroupId + ".config.tsv",
            keyFilePath = outputDir + "/" + readgroupId + ".config.keys"
    }

    Object configValues = if (defined(config.tsvOutput) && size(config.tsvOutput) > 0)
        then read_map(config.tsvOutput)
        else { "": "" }

    call qualityReport.QualityReport as qualityReportR1 {
        input:
            read = configValues.R1,
            outputDir = outputDir + "/raw/R1",
            extractAdapters = true
    }

    call qualityReport.QualityReport as qualityReportR2 {
        input:
            read = configValues.R2,
            outputDir = outputDir + "/raw/R2",
            extractAdapters = true
    }


    call adapterClipping.AdapterClipping as qc {
        input:
            outputDir = outputDir + "/QC",
            read1 = configValues.R1,
            read2 = configValues.R2,
            adapterListRead1 = qualityReportR1.adapters,
            adapterListRead2 = qualityReportR2.adapters
    }

    call wdlMapping.AlignBwaMem as mapping {
        input:
            inputR1 = qc.read1afterClipping,
            inputR2 = qc.read2afterClipping,
            outputDir = outputDir + "/alignment",
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId
    }

    output {
        File inputR1 = configValues.R1
        File inputR2 = configValues.R2
        File bamFile = mapping.bamFile
        File bamIndexFile = mapping.bamIndexFile
    }
}
