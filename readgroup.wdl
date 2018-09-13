version 1.0

import "QC/QC.wdl" as qcWorkflow
import "aligning/align-bwamem.wdl" as wdlMapping
import "structs.wdl" as structs
import "tasks/bwa.wdl" as bwa
import "tasks/common.wdl" as common

workflow Readgroup {
    input {
        Sample sample
        Library library
        Readgroup readgroup
        String outputDir
        ChipSeqInput chipSeqInput
    }

    # FIXME: workaround for namepace issue in cromwell
    String sampleId = sample.id
    String libraryId = library.id
    String readgroupId = readgroup.id

    call qcWorkflow.QC as qc {
        input:
            outputDir = outputDir,
            reads = readgroup.reads,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId
    }

    call wdlMapping.AlignBwaMem as alignBwaMem {
        input:
            inputFastq = qc.readsAfterQC,
            outputDir = outputDir,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId,
            bwaIndex = chipSeqInput.bwaIndex
    }

    output {
        FastqPair inputReads = readgroup.reads
        FastqPair cleanReads = qc.readsAfterQC
        IndexedBamFile bamFile = alignBwaMem.bamFile
    }
}
