version 1.0

import "tasks/bwa.wdl" as bwa
import "tasks/common.wdl" as common

struct Readgroup {
    String id
    File R1
    File? R1_md5
    File? R2
    File? R2_md5
}

struct Library {
    String id
    Array[Readgroup] readgroups
}

struct Sample {
    String id
    Array[Library] libraries
}

struct Root {
    Array[Sample] samples
}

struct ChipSeqInput {
    Reference reference
    BwaIndex bwaIndex
}
