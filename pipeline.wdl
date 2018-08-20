version 1.0

import "sample.wdl" as sampleWorkflow
import "structs.wdl" as structs
import "tasks/biopet.wdl" as biopet
import "tasks/bwa.wdl" as bwa

workflow pipeline {
    input {
        Array[File] sampleConfigFiles
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
        BwaIndex bwaIndex
    }

    call biopet.SampleConfigCromwellArrays as configFile {
      input:
        inputFiles = sampleConfigFiles,
        outputPath = "samples.json"
    }

    Root config = read_json(configFile.outputFile)

    scatter (sample in config.samples) {
        call sampleWorkflow.Sample as sampleTasks {
            input:
                refFasta = refFasta,
                refDict = refDict,
                refFastaIndex = refFastaIndex,
                sample = sample,
                outputDir = outputDir + "/samples/" + sample.id,
                bwaIndex = bwaIndex
        }
    }

    output {

    }
}