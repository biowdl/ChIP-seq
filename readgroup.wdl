version 1.0

import "QC/AdapterClipping.wdl" as adapterClipping
import "QC/QualityReport.wdl" as qualityReport
import "aligning/align-bwamem.wdl" as wdlMapping
import "structs.wdl" as structs

workflow readgroup {
    input {
        Sample sample
        Library library
        Readgroup readgroup
        String outputDir
    }

    call qualityReport.QualityReport as qualityReportR1 {
        input:
            read = readgroup.R1,
            outputDir = outputDir + "/raw/R1",
            extractAdapters = true
    }

    if (defined(readgroup.R2)) {
        call qualityReport.QualityReport as qualityReportR2 {
            input:
                read = select_first([readgroup.R2]),
                outputDir = outputDir + "/raw/R2",
                extractAdapters = true
        }
    }

    call adapterClipping.AdapterClipping as qc {
        input:
            outputDir = outputDir + "/QC",
            read1 = readgroup.R1,
            read2 = readgroup.R2,
            adapterListRead1 = qualityReportR1.adapters,
            adapterListRead2 = qualityReportR2.adapters
    }

    call wdlMapping.AlignBwaMem as mapping {
        input:
            inputR1 = qc.read1afterClipping,
            inputR2 = qc.read2afterClipping,
            outputDir = outputDir + "/alignment",
            sample = sample.id,
            library = library.id,
            readgroup = readgroup.id
    }

    output {
        File inputR1 = readgroup.R1
        File? inputR2 = readgroup.R2
        File bamFile = mapping.bamFile
        File bamIndexFile = mapping.bamIndexFile
    }
}
