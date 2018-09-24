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
    IndexedBamFile bam
    String? control
}