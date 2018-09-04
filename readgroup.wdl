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

    if (defined(readgroup.R1_md5)) {
        call common.CheckFileMD5 as md5CheckR1 {
            input:
                file = readgroup.R1,
                MD5sum = select_first([readgroup.R1_md5])
        }
    }

    if (defined(readgroup.R2_md5) && defined(readgroup.R2)) {
        call common.CheckFileMD5 as md5CheckR2 {
            input:
                file = select_first([readgroup.R2]),
                MD5sum = select_first([readgroup.R2_md5])
        }
    }

    call qcWorkflow.QC as qc {
        input:
            outputDir = outputDir,
            read1 = readgroup.R1,
            read2 = readgroup.R2,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId
    }

    call wdlMapping.AlignBwaMem as alignBwaMem {
        input:
            inputR1 = qc.read1afterQC,
            inputR2 = qc.read2afterQC,
            outputDir = outputDir,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId,
            bwaIndex = chipSeqInput.bwaIndex
    }

    output {
        File inputR1 = readgroup.R1
        File? inputR2 = readgroup.R2
        File cleanR1 = qc.read1afterQC
        File? cleanR2 = qc.read2afterQC
        File bamFile = alignBwaMem.bamFile
        File bamIndexFile = alignBwaMem.bamIndexFile
    }
}
