version 1.0

import "library.wdl" as libraryWorkflow
import "tasks/biopet.wdl" as biopet

workflow sample {
    input {
        Array[File] sampleConfigs
        String sampleId
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
    }

    call biopet.SampleConfig as librariesConfigs {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            jsonOutputPath = outputDir + "/" + sampleId + ".config.json",
            tsvOutputPath = outputDir + "/" + sampleId + ".config.tsv",
            keyFilePath = outputDir + "/" + sampleId + ".config.keys"
    }

    scatter (lb in read_lines(librariesConfigs.keysFile)) {
        if (lb != "") {
            call libraryWorkflow.library as library {
                input:
                    outputDir = outputDir + "/lib_" + lb,
                    sampleConfigs = select_all([librariesConfigs.jsonOutput]),
                    libraryId = lb,
                    sampleId = sampleId,
                    refFasta = refFasta,
                    refDict = refDict,
                    refFastaIndex = refFastaIndex
            }
        }
    }

    output {
        Array[String] libraries = read_lines(librariesConfigs.keysFile)
    }
}