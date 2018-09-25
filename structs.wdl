version 1.0

import "tasks/bwa.wdl" as bwa
import "tasks/common.wdl" as common

struct Readgroup {
    String id
    FastqPair reads
}

struct Library {
    String id
    Array[Readgroup] readgroups
}

struct Sample {
    String id
    String? control
    Array[Library] libraries
}

struct Root {
    Array[Sample] samples
}

struct ChipSeqInput {
    Reference reference
    BwaIndex bwaIndex
}

struct SampleResults {
    String sampleID
    IndexedBamFile bam
    String? controlID
}

struct Macs2Input {
    String sampleID
    String? controlID
    File inputBams
    File inputBamsIndex
    File? controlBams
    File? controlBamsIndex
}